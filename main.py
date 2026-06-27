import os
import sys
import subprocess
import traceback

from platform_utils import IS_WINDOWS, IS_MACOS, IS_LINUX, ensure_single_instance, set_window_bottom, set_window_topmost, show_error_dialog

if IS_WINDOWS:
    os.environ['QT_QPA_PLATFORM'] = 'windows'


def main():
    from PySide6.QtCore import QUrl, Qt, QMetaObject, Q_ARG
    from PySide6.QtGui import QFontDatabase, QIcon
    from PySide6.QtWidgets import QApplication, QMessageBox, QSystemTrayIcon
    from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent, qmlRegisterSingletonType
    from PySide6.QtQuick import QQuickWindow

    from cses_parser import CsesParser
    from style_manager import StyleManager
    from plugin_manager import PluginManager

    if not ensure_single_instance():
        return 0

    app = QApplication(sys.argv)
    app.setApplicationName("ClassBoard")
    app.setOrganizationName("NEO")

    if getattr(sys, 'frozen', False):
        base_dir = sys._MEIPASS
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
    font_dir = os.path.join(base_dir, "MiSans", "ttf")
    for name in ["MiSans-Regular.ttf", "MiSans-Bold.ttf", "MiSans-Medium.ttf"]:
        path = os.path.join(font_dir, name)
        if os.path.exists(path):
            QFontDatabase.addApplicationFont(path)

    if IS_MACOS:
        app.setAttribute(Qt.AA_DontCreateNativeWidgetSiblings, True)
        app.setStyle('fusion')
    elif IS_LINUX:
        app.setStyle('fusion')

    cses_parser = CsesParser()

    style_manager = StyleManager()
    qmlRegisterSingletonType(StyleManager, "md3.Core", 1, 0, "StyleManager",
                             lambda engine: style_manager)

    engine = QQmlApplicationEngine()
    app.setWindowIcon(QIcon(os.path.join(base_dir, "icons", "logo.ico")))
    engine.rootContext().setContextProperty("csesParser", cses_parser)
    engine.addImportPath(base_dir)
    if not os.path.isdir(os.path.join(base_dir, "md3")):
        parent_dir = os.path.dirname(base_dir)
        if parent_dir and os.path.isdir(os.path.join(parent_dir, "md3")):
            engine.addImportPath(parent_dir)
    qml_modules_dir = os.path.join(base_dir, "qml")
    if os.path.isdir(qml_modules_dir):
        engine.addImportPath(qml_modules_dir)

    builtin_plugins_dir = os.path.join(base_dir, "plugins")
    user_plugins_dir = PluginManager.default_plugins_dir()
    os.makedirs(user_plugins_dir, exist_ok=True)
    plugins_dirs = [user_plugins_dir]
    if os.path.isdir(builtin_plugins_dir) and os.path.normpath(builtin_plugins_dir) != os.path.normpath(user_plugins_dir):
        plugins_dirs.append(builtin_plugins_dir)
    plugin_manager = PluginManager(
        plugins_dirs=plugins_dirs,
        context={"engine": engine, "csesParser": cses_parser},
    )
    engine.rootContext().setContextProperty("pluginManager", plugin_manager)
    engine.rootContext().setContextProperty("_platform", {
        "isWindows": IS_WINDOWS,
        "isMacOS": IS_MACOS,
        "isLinux": IS_LINUX,
    })

    engine.objectCreationFailed.connect(lambda: app.exit(-1))

    main_qml = os.path.join(base_dir, "main.qml")
    engine.load(QUrl.fromLocalFile(main_qml))

    if not engine.rootObjects():
        print("No root objects after loading QML!")
        return -1

    main_window = None
    for obj in engine.rootObjects():
        if isinstance(obj, QQuickWindow):
            main_window = obj
            break

    if main_window is None:
        print("No main window found!")
        return -1

    def update_window_z_order():
        if not IS_WINDOWS:
            return
        hwnd = int(main_window.winId())
        if cses_parser.alwaysOnBottom:
            set_window_bottom(hwnd)
        else:
            set_window_topmost(hwnd)

    cses_parser.alwaysOnBottomChanged.connect(update_window_z_order)
    update_window_z_order()

    if cses_parser.hasPendingSwaps():
        ret = QMessageBox.question(None, "换课恢复",
            "检测到今天有换课记录:\n" + cses_parser.swapsSummary() + "\n\n是否继续使用？",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
        if ret == QMessageBox.StandardButton.No:
            cses_parser.clearSwaps()

    tray_icon = QSystemTrayIcon(app)
    tray_icon.setIcon(QIcon(os.path.join(base_dir, "icons", "logo.ico")))
    tray_icon.setToolTip("NEO ClassBoard")
    tray_icon.setVisible(True)

    def toggle_window():
        QMetaObject.invokeMethod(main_window, "toggleVisibility")

    def load_qml_window(qml_name):
        qml_path = os.path.join(base_dir, qml_name)
        comp = QQmlComponent(engine, QUrl.fromLocalFile(qml_path))
        if comp.isError():
            err = comp.errorString()
            QMessageBox.critical(None, "QML 加载错误", f"Failed to load {qml_path}:\n{err}")
            return
        obj = comp.create()
        if obj is None:
            details = "\n\n".join(str(e) for e in comp.errors())
            QMessageBox.critical(None, "QML 创建错误", f"Failed to create {qml_path}:\n{details}")
            return
        win = obj if isinstance(obj, QQuickWindow) else None
        if win:
            win.setVisible(True)
        else:
            QMessageBox.warning(None, "QML 类型错误", f"Loaded QML is not a Window: {qml_path}")
            obj.deleteLater()

    tray_menu_comp = QQmlComponent(engine, QUrl.fromLocalFile(os.path.join(base_dir, "TrayMenu.qml")))
    if tray_menu_comp.isError():
        QMessageBox.critical(None, "QML 加载错误", f"Failed to load TrayMenu.qml:\n{tray_menu_comp.errorString()}")
        return -1
    tray_menu_obj = tray_menu_comp.create()
    if tray_menu_obj is None:
        details = "\n\n".join(str(e) for e in tray_menu_comp.errors())
        QMessageBox.critical(None, "QML 创建错误", f"Failed to create TrayMenu:\n{details}")
        return -1

    tray_menu_obj.showHideRequested.connect(toggle_window)
    tray_menu_obj.settingsRequested.connect(lambda: load_qml_window("SettingsDialog.qml"))
    tray_menu_obj.swapRequested.connect(lambda: load_qml_window("ClassSwapDialog.qml"))
    tray_menu_obj.rescheduleRequested.connect(lambda day: cses_parser.setRescheduleDay(day))
    tray_menu_obj.quitRequested.connect(lambda: QMetaObject.invokeMethod(main_window, "requestClose"))

    def show_tray_menu(reason):
        if IS_MACOS:
            geo = tray_icon.geometry()
            pos = geo.center()
            QMetaObject.invokeMethod(tray_menu_obj, "showAt", Q_ARG("QVariant", pos.x()), Q_ARG("QVariant", pos.y()))
        elif reason == QSystemTrayIcon.ActivationReason.Context:
            geo = tray_icon.geometry()
            pos = geo.center()
            QMetaObject.invokeMethod(tray_menu_obj, "showAt", Q_ARG("QVariant", pos.x()), Q_ARG("QVariant", pos.y()))
        elif reason == QSystemTrayIcon.ActivationReason.Trigger:
            toggle_window()

    tray_icon.activated.connect(show_tray_menu)

    if os.environ.get('CLASSBOARD_DEBUG_SETTINGS'):
        from PySide6.QtCore import QTimer
        QTimer.singleShot(1000, lambda: load_qml_window("SettingsDialog.qml"))

    return app.exec()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        show_error_dialog("ClassBoard 启动失败", traceback.format_exc())
        sys.exit(1)
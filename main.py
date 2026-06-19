import os
import sys

if sys.platform == 'win32':
    os.environ['QT_QPA_PLATFORM'] = 'windows'

from PySide6.QtCore import QUrl, Qt
from PySide6.QtGui import QFontDatabase, QIcon
from PySide6.QtWidgets import QApplication, QMessageBox, QMenu, QSystemTrayIcon
from PySide6.QtGui import QAction, QActionGroup
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent, qmlRegisterSingletonType
from PySide6.QtQuick import QQuickWindow

from cses_parser import CsesParser
from style_manager import StyleManager


def ensure_single_instance():
    if sys.platform != 'win32':
        return True
    import ctypes
    kernel32 = ctypes.windll.kernel32
    h_mutex = kernel32.CreateMutexW(None, True, "ClassBoard_SingleInstance_Mutex")
    if kernel32.GetLastError() == 183:
        QMessageBox.warning(None, "ClassBoard", "已有程序正在运行，请勿重复启动。")
        return False
    return True


def main():
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

    cses_parser = CsesParser()

    style_manager = StyleManager()
    qmlRegisterSingletonType(StyleManager, "md3.Core", 1, 0, "StyleManager",
                             lambda engine: style_manager)

    engine = QQmlApplicationEngine()
    app.setWindowIcon(QIcon(os.path.join(base_dir, "icons", "logo.ico")))
    engine.rootContext().setContextProperty("csesParser", cses_parser)
    engine.addImportPath(base_dir)
    qml_modules_dir = os.path.join(base_dir, "qml")
    if os.path.isdir(qml_modules_dir):
        engine.addImportPath(qml_modules_dir)

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
        if sys.platform != 'win32':
            return
        import ctypes
        from ctypes import wintypes
        user32 = ctypes.windll.user32
        hwnd = wintypes.HWND(int(main_window.winId()))
        GWL_EXSTYLE = -20
        WS_EX_TOPMOST = 0x00000008
        HWND_BOTTOM = wintypes.HWND(1)
        HWND_TOPMOST = wintypes.HWND(-1)
        flags = 0x0001 | 0x0002 | 0x0020
        user32.SetWindowPos.argtypes = [wintypes.HWND, wintypes.HWND, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_uint]
        user32.SetWindowPos.restype = wintypes.BOOL
        exstyle = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
        if cses_parser.alwaysOnBottom:
            exstyle &= ~WS_EX_TOPMOST
            user32.SetWindowLongW(hwnd, GWL_EXSTYLE, exstyle)
            user32.SetWindowPos(hwnd, HWND_BOTTOM, 0, 0, 0, 0, flags)
        else:
            exstyle |= WS_EX_TOPMOST
            user32.SetWindowLongW(hwnd, GWL_EXSTYLE, exstyle)
            user32.SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, flags)
        user32.UpdateWindow(hwnd)

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

    tray_menu = QMenu()
    act_show = tray_menu.addAction(QIcon(os.path.join(base_dir, "icons", "dashboard.svg")), "显示/隐藏")
    act_settings = tray_menu.addAction(QIcon(os.path.join(base_dir, "icons", "settings.svg")), "设置")
    
    reschedule_menu = tray_menu.addMenu("调休日")
    reschedule_menu.setIcon(QIcon(os.path.join(base_dir, "icons", "schedule.svg")))
    reschedule_group = QActionGroup(reschedule_menu)
    act_reschedule_none = reschedule_menu.addAction("不调休")
    act_reschedule_none.setCheckable(True)
    act_reschedule_none.setChecked(True)
    reschedule_group.addAction(act_reschedule_none)
    day_names = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    for d in range(1, 8):
        act = reschedule_menu.addAction(day_names[d])
        act.setCheckable(True)
        act.setData(d)
        reschedule_group.addAction(act)
    tray_menu.addSeparator()
    act_swap = tray_menu.addAction(QIcon(os.path.join(base_dir, "icons", "swap.svg")), "换课")
    act_quit = tray_menu.addAction("退出")
    tray_icon.setContextMenu(tray_menu)

    def toggle_window():
        if main_window.isVisible():
            main_window.hide()
        else:
            main_window.show()

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

    def on_reschedule_triggered(act):
        day = act.data() or 0
        cses_parser.setRescheduleDay(day)

    act_show.triggered.connect(toggle_window)
    act_settings.triggered.connect(lambda: load_qml_window("SettingsDialog.qml"))
    
    act_swap.triggered.connect(lambda: load_qml_window("ClassSwapDialog.qml"))
    reschedule_group.triggered.connect(on_reschedule_triggered)
    act_quit.triggered.connect(app.quit)

    tray_icon.activated.connect(lambda reason:
        toggle_window() if reason == QSystemTrayIcon.ActivationReason.Trigger else None)

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
import os
import sys
import traceback

os.environ['QT_QPA_PLATFORM'] = 'windows'

from PySide6.QtCore import QUrl, Qt, qInstallMessageHandler, QtMsgType, QTimer
from PySide6.QtGui import QFontDatabase
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent, qmlRegisterSingletonType
from PySide6.QtQuick import QQuickWindow

from cses_parser import CsesParser
from style_manager import StyleManager
from plugin_manager import PluginManager

messages = []

def msg_handler(msg_type, context, message):
    level = {QtMsgType.QtDebugMsg: "DEBUG", QtMsgType.QtWarningMsg: "WARN",
             QtMsgType.QtCriticalMsg: "CRIT", QtMsgType.QtFatalMsg: "FATAL",
             QtMsgType.QtInfoMsg: "INFO"}.get(msg_type, "?")
    messages.append(f"[{level}] {message}")

qInstallMessageHandler(msg_handler)

app = QApplication(sys.argv)
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
engine.addImportPath(base_dir)
if not os.path.isdir(os.path.join(base_dir, "md3")):
    parent_dir = os.path.dirname(base_dir)
    if parent_dir and os.path.isdir(os.path.join(parent_dir, "md3")):
        engine.addImportPath(parent_dir)

plugins_dir = os.path.join(base_dir, "plugins")
plugin_manager = PluginManager(plugins_dirs=plugins_dir, context={"engine": engine})

engine.rootContext().setContextProperty("csesParser", cses_parser)
engine.rootContext().setContextProperty("pluginManager", plugin_manager)

print("=== Loading SettingsDialog.qml ===")
qml_path = os.path.join(base_dir, "SettingsDialog.qml")
comp = QQmlComponent(engine, QUrl.fromLocalFile(qml_path))
if comp.isError():
    print("SettingsDialog load errors:")
    for e in comp.errors():
        print("  ", e.toString())
    sys.exit(1)

obj = comp.create()
if obj is None:
    print("Failed to create SettingsDialog object")
    sys.exit(1)

print("SettingsDialog created OK, type:", type(obj).__name__)
print("Is QQuickWindow:", isinstance(obj, QQuickWindow))

try:
    obj.setVisible(True)
    print("setVisible(True) OK")
except Exception as e:
    print("setVisible error:", e)
    traceback.print_exc()

try:
    ret = obj.setProperty("currentPage", 2)
    print("setProperty currentPage=2 returned:", ret)
except Exception as e:
    print("setProperty error:", e)
    traceback.print_exc()

QTimer.singleShot(2000, app.quit)
app.exec()

print()
print("=== All QML Messages ===")
for m in messages:
    print(m)
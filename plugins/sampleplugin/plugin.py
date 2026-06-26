from classboard_plugin import ClassBoardPlugin


class SamplePlugin(ClassBoardPlugin):
    PLUGIN_ID = "sample"
    PLUGIN_NAME = "示例插件"
    PLUGIN_VERSION = "1.0"
    PLUGIN_AUTHOR = "NEO ClassBoard"
    PLUGIN_DESCRIPTION = "一个示例插件，演示 1.3.0 插件系统的动态加载与 QML 组件注册。"
    PLUGIN_QML = "SampleWidget.qml"
    PREFERRED_WIDTH = 80
    FILL_WIDTH = False
# NEO ClassBoard 插件开发文档

适用于 **NEO ClassBoard 1.3.0+**（PySide6 + QML）。

NEO ClassBoard 的插件系统允许第三方扩展主界面的小组件。每个插件是一个独立文件夹，包含一个 Python 入口（`plugin.py`）和一个 QML 组件，由应用在启动时自动发现并加载，无需重新编译。

---

## 一、快速开始

### 1. 目录结构

每个插件是 `plugins/` 下的一个子文件夹，至少包含 `plugin.py` 和一个 QML 文件：

```
plugins/
└── myplugin/
    ├── plugin.py          # 必需，插件入口
    ├── MyWidget.qml       # 必需，插件组件
    └── icon.svg           # 可选，插件图标
```

### 2. 最小示例

`plugin.py`：

```python
from classboard_plugin import ClassBoardPlugin


class MyPlugin(ClassBoardPlugin):
    PLUGIN_ID = "myplugin"
    PLUGIN_NAME = "我的插件"
    PLUGIN_VERSION = "1.0"
    PLUGIN_AUTHOR = "你的名字"
    PLUGIN_DESCRIPTION = "一个自定义小组件。"
    PLUGIN_QML = "MyWidget.qml"
    PLUGIN_ICON = "icon.svg"
    PREFERRED_WIDTH = 120
    FILL_WIDTH = False
```

`MyWidget.qml`：

```qml
import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        radius: Theme.shape.cornerMedium
        color: Theme.color.primaryContainer

        Text {
            anchors.centerIn: parent
            text: "Hello"
            font.family: Theme.typography.titleMedium.family
            font.pixelSize: Theme.typography.titleMedium.size
            font.weight: Font.Bold
            color: Theme.color.onPrimaryContainerColor
        }
    }
}
```

将文件夹放入 `plugins/` 后启动应用，插件会自动出现在 **设置 → 插件** 页面。

---

## 二、插件接口

继承 `ClassBoardPlugin` 基类（定义在 `classboard_plugin.py`），通过类属性声明插件元数据。

### 类属性

| 属性 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `PLUGIN_ID` | `str` | 是 | 插件唯一标识，用作组件 ID。必须全局唯一，建议用英文小写。 |
| `PLUGIN_NAME` | `str` | 否 | 显示名称，缺省时回退到 `PLUGIN_ID`。 |
| `PLUGIN_VERSION` | `str` | 否 | 版本号，缺省 `"1.0"`。 |
| `PLUGIN_AUTHOR` | `str` | 否 | 作者名。 |
| `PLUGIN_DESCRIPTION` | `str` | 否 | 插件描述，显示在插件列表与详情中。 |
| `PLUGIN_QML` | `str` | 是 | QML 组件文件名（相对插件目录）。 |
| `PLUGIN_ICON` | `str` | 否 | 图标文件名（相对插件目录）。缺省时显示默认拼图图标。 |
| `PREFERRED_WIDTH` | `int` | 否 | 组件首选宽度（像素）。`0` 表示自适应。 |
| `FILL_WIDTH` | `bool` | 否 | 是否填充主界面剩余宽度。缺省 `False`。 |

### 生命周期方法

```python
def initialize(self) -> None:
    """插件加载后调用一次。可在此注册 QML 类型、读取配置等。"""

def finalize(self) -> None:
    """插件卸载前调用。可在此释放资源、保存状态等。"""
```

### 访问宿主上下文

插件可通过 `self.context` 访问宿主注入的对象：

```python
def initialize(self) -> None:
    engine = self.context.get("engine")        # QQmlApplicationEngine
    cses_parser = self.context.get("csesParser")  # 课表数据解析器
    plugin_dir = self.plugin_dir               # 本插件所在目录的绝对路径
```

---

## 三、QML 组件开发

### 1. 根元素

QML 组件的根元素应为 `Item`，并设置 `anchors.fill: parent` 以填充分配的组件槽位：

```qml
Item {
    id: root
    anchors.fill: parent
    // ...
}
```

### 2. 使用 MD3 主题

应用内置 Material Design 3 主题，通过 `import md3.Core` 引入 `Theme`：

- **颜色**：`Theme.color.primary`、`Theme.color.onSurfaceColor`、`Theme.color.surfaceContainer` 等
- **字体**：`Theme.typography.titleMedium`、`Theme.typography.bodySmall` 等（`.family` / `.size` / `.weight`）
- **形状**：`Theme.shape.cornerMedium`、`Theme.shape.cornerLarge` 等

建议使用 MD3 颜色与字体，以保证与主界面风格一致。

### 3. 访问课表数据

QML 中可直接使用全局对象 `csesParser`（已注册为上下文属性），读取课表信息：

```qml
Text {
    text: csesParser.loaded ? "已加载课表" : "未加载"
}
```

常用属性：`csesParser.componentOrder`、`csesParser.componentVisibility`、`csesParser.filePath` 等。

### 4. 宽度策略

- **固定宽度**：设置 `PREFERRED_WIDTH`（如 `120`），组件占据该宽度。
- **填充剩余宽度**：设置 `FILL_WIDTH = True`，组件会拉伸填满主界面剩余空间（同一行仅一个组件可填充）。
- **自适应**：`PREFERRED_WIDTH = 0` 且 `FILL_WIDTH = False`，使用默认布局宽度。

### 5. 插件设置 API

插件可声明用户可配置的设置项，这些设置会自动渲染到「设置 → 插件 → 选中插件 → 插件设置」区域，并持久化到插件目录下的 `settings.json`。

#### 声明设置项

在插件类中重写 `settings()` 方法，返回设置项描述列表：

```python
def settings(self) -> list:
    return [
        {
            "key": "fontSize",        # 唯一键
            "label": "字体大小",       # 显示标签
            "type": "int",            # int|double|string|bool|choice
            "default": 14,            # 默认值
            "min": 8, "max": 32,      # 可选，int/double 的范围
        },
        {
            "key": "colorScheme",
            "label": "配色",
            "type": "choice",          # choice 必须提供 options
            "default": "tertiary",
            "options": [
                {"value": "tertiary", "label": "青色"},
                {"value": "primary", "label": "蓝色"},
            ],
        },
        {
            "key": "showLabel",
            "label": "显示名称",
            "type": "bool",
            "default": True,
        },
        {
            "key": "title",
            "label": "标题文字",
            "type": "string",
            "default": "倒计日",
        },
    ]
```

#### 支持的类型与控件

| type     | 控件        | 额外字段                |
|----------|-------------|-------------------------|
| `bool`   | Switch 开关 | —                       |
| `int`    | Slider 滑块 | `min`, `max`（可选）    |
| `double` | Slider 滑块 | `min`, `max`（可选）    |
| `string` | TextField   | —                       |
| `choice` | ComboBox    | `options`（必填）      |

#### 在 QML 中读取设置

通过 `pluginManager.pluginInstance(compId)` 获取插件实例，再调用 `getSetting(key)`：

```qml
Item {
    id: root

    readonly property var pluginInst: {
        var pm = pluginManager
        if (!pm || !pm.pluginInstance) return null
        return pm.pluginInstance("countdown")
    }

    // 用版本号触发重新求值（设置改变时刷新）
    property int _settingsRev: 0
    Connections {
        target: pluginInst
        function onSettingsChanged() { root._settingsRev++ }
    }

    readonly property int cfgFontSize: {
        root._settingsRev  // 依赖此变量以在设置变更时刷新
        return pluginInst ? (pluginInst.getSetting("fontSize") || 26) : 26
    }

    Text {
        font.pixelSize: root.cfgFontSize
        text: "..."
    }
}
```

> **提示**：`getSetting()` 是普通函数调用，QML 绑定无法自动追踪其变化。因此用一个 `_settingsRev` 计数器，在 `settingsChanged` 信号触发时自增，并在绑定中引用它，即可让设置变更实时反映到 UI。

#### 在 Python 中读写设置

插件代码内部也可直接调用：

```python
def initialize(self) -> None:
    # 读取设置
    font_size = self.getSetting("fontSize")
    # 写入设置（会自动保存到 settings.json 并发出 settingsChanged 信号）
    self.setSetting("fontSize", 20)
```

设置自动持久化，无需手动管理文件。

#### 自定义设置组件

当设置项 API（bool/int/string/choice）不足以表达复杂配置时，插件可提供一个自定义 QML 设置组件，它会渲染到插件详情页的「插件设置」区域下方。

声明方式：设置 `PLUGIN_SETTINGS_QML` 类属性指向一个 QML 文件：

```python
class MyPlugin(ClassBoardPlugin):
    PLUGIN_QML = "MyWidget.qml"
    PLUGIN_SETTINGS_QML = "MySettingsWidget.qml"  # 自定义设置组件
```

设置组件的根元素应为 `ColumnLayout`（自动填宽），内部通过 `pluginManager.pluginInstance(compId)` 访问插件实例与数据：

```qml
import QtQuick
import QtQuick.Layouts
import md3.Core

ColumnLayout {
    Layout.fillWidth: true
    spacing: 10

    property var pluginInst: pluginManager.pluginInstance("myplugin")
    property var store: pluginInst ? pluginInst.store : null

    // ... 自定义管理 UI（列表、输入、日期选择等）
}
```

> **设计原则**：主界面组件（`PLUGIN_QML`）只负责显示信息，数据管理操作（增删改）应放在设置组件（`PLUGIN_SETTINGS_QML`）中，保持组件轻量。

---

## 四、安装与管理

### 安装方式

在应用内 **设置 → 插件** 页面操作：

1. **导入文件夹**：选择包含 `plugin.py` 的本地文件夹，复制到 `plugins/` 目录。
2. **导入压缩包**：选择 `.zip` 压缩包，解压到 `plugins/` 目录。压缩包根目录必须包含 `plugin.py`。
3. **刷新**：重新扫描并加载所有插件（开发时修改代码后可用此热重载）。

### 卸载

在插件列表中选中插件，点击 **卸载**，会删除插件文件夹并从组件栏移除该组件。

### 手动安装

直接将插件文件夹放入应用目录下的 `plugins/` 文件夹，重启应用即可。

---

## 五、打包分发

### 压缩包格式

将插件文件夹打包为 `.zip`，确保解压后根目录直接是插件文件：

```
myplugin.zip
└── myplugin/
    ├── plugin.py
    ├── MyWidget.qml
    └── icon.svg
```

> 注意：`plugin.py` 必须在解压后的根目录（或子文件夹根目录），否则导入会失败。

### 依赖

- 插件可使用 Python 标准库。
- 如需第三方依赖，需确保目标环境已安装，或随插件一并打包。
- QML 中仅可使用应用已提供的模块（`QtQuick`、`QtQuick.Layouts`、`md3.Core` 等）。

---

## 六、完整示例

### 基础示例：计数器

参见 `plugins/sampleplugin/`：

- [plugin.py](plugins/sampleplugin/plugin.py) — 插件入口
- [SampleWidget.qml](plugins/sampleplugin/SampleWidget.qml) — 点击计数器组件

该插件展示了一个可点击的计数器，演示了元数据声明、QML 组件注册与 MD3 主题使用的完整流程。

### 进阶示例：倒计日

参见 `plugins/countdown/`：

- [plugin.py](plugins/countdown/plugin.py) — 插件入口，含数据存储（`CountdownStore`）与设置声明（`settings()`）
- [CountdownWidget.qml](plugins/countdown/CountdownWidget.qml) — 显示/编辑双模式组件，接入设置 API

该插件演示了：
- **插件设置 API**：声明 `bool`/`int`/`choice`/`string` 四种设置项，QML 通过 `pluginInstance().getSetting()` 读取并应用（标题、字号、配色、显隐）
- **数据持久化**：自定义 `CountdownStore`（QObject）管理倒计日列表，保存到 `config.json`
- **双模式 UI**：点击切换显示/编辑模式，Canvas 自绘删除图标
- **QObject 暴露**：通过 `store` 常量属性将数据对象暴露给 QML

---

## 七、注意事项

1. **PLUGIN_ID 唯一性**：重复的 ID 会被忽略，仅保留首个加载的插件。
2. **插件隔离**：每个插件在独立目录中运行，QML 导入路径已自动添加，可直接 `import` 同目录模块。
3. **错误处理**：插件加载失败不会崩溃应用，错误会记录到日志，插件不会出现在列表中。
4. **热重载**：开发时修改 `plugin.py` 后点击「刷新」即可重新加载，无需重启应用。
5. **图标**：建议使用 SVG 格式，尺寸 24×24。未提供图标时显示默认拼图图标。
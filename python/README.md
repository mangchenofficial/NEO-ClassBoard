# NEO ClassBoard

基于 PySide6 + QML 的桌面课表小组件，常驻于桌面顶部，实时显示当前/下一节课信息，支持换课、调休、提示音、自动隐藏等实用功能。

## 功能特性

- **实时课表显示**：当前课程高亮，自动切换到下一节
- **换课**：临时调整某天的课程顺序，支持恢复
- **调休日**：将周末按指定工作日课表运行
- **提示音**：课前/课中/课末自定义提示音与音量
- **自动隐藏**：上课时隐藏、窗口最大化时隐藏、全屏时隐藏
- **置顶/置底**：始终在最前或在最底（不遮挡其他窗口）
- **迷你模式**：紧凑显示，节省屏幕空间
- **悬停淡出**：鼠标移开时降低透明度
- **缩放与透明度**：自定义小组件大小与不透明度
- **字体切换**：内置 MiSans 字体，可自定义
- **系统托盘**：托盘图标快速访问所有功能
- **单实例运行**：防止重复启动

## 技术栈

- Python 3.14+
- PySide6 6.6+（Qt for Python）
- QML / QtQuick（界面）
- 自实现轻量 YAML 解析器（解析 CSES 课表文件）

## 目录结构

```
python/
├── main.py                 # 程序入口
├── main.qml                # 主窗口（课表小组件）
├── cses_parser.py          # 课表解析与状态管理
├── style_manager.py        # 主题/配色管理
├── SettingsDialog.qml      # 设置对话框
├── ClassSwapDialog.qml     # 换课对话框
├── ClassList.qml           # 课表列表
├── ComponentSettingsPage.qml
├── NextClassWidget.qml
├── Settings.qml
├── TimeSection.qml
├── Icon.qml
├── build.spec              # PyInstaller 打包配置
├── requirements.txt
├── MiSans/ttf/             # 内置字体
├── icons/                  # 图标资源
└── md3/                    # Material Design 3 组件库
    └── Core/
        ├── Controls/       # 各类控件
        ├── Styles/          # 主题与动画
        └── qmldir
```

## 环境要求

- Windows 10/11（64 位）
- Python 3.14+
- PySide6 6.6+

## 从源码运行

1. 安装依赖：

   ```powershell
   pip install -r requirements.txt
   ```

2. 运行程序：

   ```powershell
   python main.py
   ```

## 打包为 exe

使用 PyInstaller 打包为单文件可执行程序：

1. 安装 PyInstaller：

   ```powershell
   pip install pyinstaller
   ```

2. 执行打包（使用项目内置的 [build.spec](build.spec) 配置）：

   ```powershell
   python -m PyInstaller build.spec --noconfirm
   ```

3. 产物位于 `dist/ClassBoard.exe`（约 250 MB）。

> 打包配置已包含所有 QML 文件、字体、图标，以及 PySide6 所需的 Qt QML 模块（`QtQuick`、`QtQuick.Layouts`、`QtQuick.Effects`、`QtQuick.Window`、`QtMultimedia` 等）。

## 运行 exe

双击 `dist/ClassBoard.exe` 即可运行。

- 启动后显示课表小组件，并在系统托盘创建图标
- 右键托盘图标可访问：显示/隐藏、设置、调休日、换课、退出
- 程序已运行时再次启动会提示"已有程序正在运行"

## 数据存储

用户数据与 exe 位置无关，存放在系统 AppData 目录：

```
C:\Users\<用户名>\AppData\Local\NEO\ClassBoard\
├── schedule.yml      # 课表数据
├── config.ini        # 配置
├── swaps.ini         # 换课记录
└── notification.wav  # 自定义提示音
```

因此可随意移动或分发 exe，不会丢失配置。

## 课表文件格式

支持 CSES（Class Schedule Exchange Standard）YAML 格式。

from __future__ import annotations

import importlib.util
import json
import logging
import os
import shutil
import sys
from typing import List, Optional

from PySide6.QtCore import QObject, Property, Signal, Slot, QStandardPaths
from PySide6.QtWidgets import QFileDialog

from classboard_plugin import ClassBoardPlugin

logger = logging.getLogger(__name__)


class PluginManager(QObject):
    """Discovers, loads and exposes ClassBoard plugins to QML.

    This is the PySide6 counterpart of a QPluginLoader-based host: each plugin
    lives in its own subdirectory under one of the configured ``plugins_dirs``
    and is loaded via :mod:`importlib`. Loaded plugins are exposed to QML
    through a metadata list and resolution slots so the main widget can
    dynamically instantiate plugin components with ``Loader { source: ... }``.
    """

    pluginsChanged = Signal()
    pluginsDirChanged = Signal()

    def __init__(self, plugins_dirs, context: Optional[dict] = None,
                 parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        if isinstance(plugins_dirs, str):
            plugins_dirs = [plugins_dirs]
        self._plugins_dirs: List[str] = list(plugins_dirs)
        self._context: dict = context or {}
        self._plugins: List[ClassBoardPlugin] = []
        self._by_id: dict = {}
        self._ensure_host_on_path()
        self.load()

    @staticmethod
    def _ensure_host_on_path() -> None:
        host_dir = os.path.dirname(os.path.abspath(__file__))
        if host_dir not in sys.path:
            sys.path.insert(0, host_dir)

    @staticmethod
    def default_plugins_dir() -> str:
        base = QStandardPaths.writableLocation(QStandardPaths.AppDataLocation)
        if not base:
            base = os.path.expanduser("~/.ClassBoard")
        return os.path.join(base, "plugins")

    @Slot(result=str)
    def pluginsDir(self) -> str:
        return self._plugins_dirs[0] if self._plugins_dirs else ""

    @Slot(str, result=bool)
    def setPluginsDir(self, path: str) -> bool:
        if not path:
            return False
        path = os.path.normpath(path)
        if path in self._plugins_dirs:
            return True
        self._plugins_dirs = [path] + [d for d in self._plugins_dirs if d != path]
        os.makedirs(path, exist_ok=True)
        self.load()
        self.pluginsDirChanged.emit()
        return True

    @Slot(result=str)
    def choosePluginsDir(self) -> str:
        path = QFileDialog.getExistingDirectory(None, "选择插件存储目录", self.pluginsDir())
        if not path:
            return ""
        if self.setPluginsDir(path):
            return path
        return ""

    def load(self) -> None:
        for plugin in self._plugins:
            try:
                plugin.finalize()
            except Exception:
                logger.exception("Error finalizing plugin %s", plugin.PLUGIN_ID)
        self._plugins.clear()
        self._by_id.clear()
        for plugins_dir in self._plugins_dirs:
            if not plugins_dir or not os.path.isdir(plugins_dir):
                continue
            self._scan_dir(plugins_dir)
        self.pluginsChanged.emit()

    def _scan_dir(self, plugins_dir: str) -> None:
        engine = self._context.get("engine")
        for name in sorted(os.listdir(plugins_dir)):
            plugin_dir = os.path.join(plugins_dir, name)
            if not os.path.isdir(plugin_dir):
                continue
            plugin_py = os.path.join(plugin_dir, "plugin.py")
            if not os.path.isfile(plugin_py):
                continue
            plugin = self._load_plugin(plugin_py, plugin_dir)
            if plugin is None:
                continue
            if engine is not None:
                try:
                    engine.addImportPath(plugin_dir)
                except Exception:
                    logger.exception("addImportPath failed for %s", plugin_dir)
            self._register(plugin)

    def _load_plugin(self, plugin_py: str, plugin_dir: str):
        mod_name = "classboard_plugin_" + os.path.basename(plugin_dir)
        try:
            spec = importlib.util.spec_from_file_location(mod_name, plugin_py)
            if spec is None or spec.loader is None:
                logger.warning("Cannot create import spec for %s", plugin_py)
                return None
            module = importlib.util.module_from_spec(spec)
            sys.modules[mod_name] = module
            spec.loader.exec_module(module)
        except Exception:
            logger.exception("Failed to load plugin module %s", plugin_py)
            return None
        cls = self._find_plugin_class(module)
        if cls is None:
            logger.warning("No ClassBoardPlugin subclass found in %s", plugin_py)
            return None
        try:
            instance = cls()
            instance.set_context(self._context, plugin_dir)
            instance.initialize()
        except Exception:
            logger.exception("Failed to instantiate plugin %s", cls)
            return None
        return instance

    @staticmethod
    def _find_plugin_class(module):
        candidates = []
        for attr in dir(module):
            obj = getattr(module, attr)
            if (isinstance(obj, type)
                    and issubclass(obj, ClassBoardPlugin)
                    and obj is not ClassBoardPlugin):
                candidates.append(obj)
        if not candidates:
            return None
        for candidate in candidates:
            if getattr(candidate, "PLUGIN_ID", ""):
                return candidate
        return candidates[0]

    def _register(self, plugin: ClassBoardPlugin) -> None:
        pid = plugin.PLUGIN_ID
        if not pid:
            logger.warning("Plugin %s has no PLUGIN_ID; skipping", plugin)
            return
        if pid in self._by_id:
            logger.warning("Duplicate plugin id %r; ignoring %s", pid, plugin)
            return
        self._plugins.append(plugin)
        self._by_id[pid] = plugin

    @Property(list, notify=pluginsChanged)
    def plugins(self) -> list:
        return [p.metadata() for p in self._plugins]

    @Slot(str, result=bool)
    def isPlugin(self, compId: str) -> bool:
        return compId in self._by_id

    @Slot(str, result=str)
    def qmlUrlFor(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        return plugin.qml_url() if plugin else ""

    @Slot(str, result=str)
    def settingsQmlUrlFor(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        return plugin.settings_qml_url() if plugin else ""

    @Slot(str, result=bool)
    def hasSettings(self, compId: str) -> bool:
        plugin = self._by_id.get(compId)
        if plugin is None:
            return False
        return len(plugin.settings()) > 0 or bool(plugin.PLUGIN_SETTINGS_QML)

    @Slot(str, result="QVariant")
    def settingsSchemaFor(self, compId: str):
        plugin = self._by_id.get(compId)
        if plugin is None:
            return []
        return plugin.settingsSchema()

    @Slot(str, result="QVariant")
    def pluginInstance(self, compId: str):
        return self._by_id.get(compId)

    @Slot(str, result=str)
    def pluginName(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        return plugin.PLUGIN_NAME if plugin else ""

    @Slot(str, result=str)
    def pluginVersion(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        return plugin.PLUGIN_VERSION if plugin else ""

    @Slot(str, result=str)
    def pluginAuthor(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        return plugin.PLUGIN_AUTHOR if plugin else ""

    @Slot(str, result=str)
    def pluginDescription(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        return plugin.PLUGIN_DESCRIPTION if plugin else ""

    @Slot(str, result=str)
    def pluginIcon(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        return plugin.icon_url() if plugin else ""

    @Slot(str, result=int)
    def preferredWidth(self, compId: str) -> int:
        plugin = self._by_id.get(compId)
        return int(plugin.PREFERRED_WIDTH) if plugin else 0

    @Slot(str, result=bool)
    def fillWidth(self, compId: str) -> bool:
        plugin = self._by_id.get(compId)
        return bool(plugin.FILL_WIDTH) if plugin else False

    @Slot(result=int)
    def count(self) -> int:
        return len(self._plugins)

    @Slot(result=str)
    def importFromFolder(self) -> str:
        path = QFileDialog.getExistingDirectory(None, "选择插件文件夹", "")
        if not path:
            return ""
        return self._install_plugin(path)

    @Slot(result=str)
    def importFromArchive(self) -> str:
        path, _ = QFileDialog.getOpenFileName(
            None, "导入插件压缩包", "", "插件包 (*.zip);;所有文件 (*)")
        if not path:
            return ""
        return self._install_archive(path)

    def _install_plugin(self, src: str) -> str:
        if not self._plugins_dirs:
            return "未配置插件目录"
        if not os.path.isfile(os.path.join(src, "plugin.py")):
            return "所选文件夹不是有效的插件（缺少 plugin.py）"
        plugins_root = self._plugins_dirs[0]
        os.makedirs(plugins_root, exist_ok=True)
        name = os.path.basename(os.path.normpath(src))
        dest = os.path.join(plugins_root, name)
        if os.path.exists(dest):
            return "插件已存在：" + name
        try:
            shutil.copytree(src, dest)
        except Exception as exc:
            logger.exception("Failed to copy plugin %s", src)
            return "复制失败：" + str(exc)
        self.load()
        return "OK:" + name

    def _install_archive(self, archive: str) -> str:
        import zipfile
        if not self._plugins_dirs:
            return "未配置插件目录"
        plugins_root = self._plugins_dirs[0]
        os.makedirs(plugins_root, exist_ok=True)
        name = os.path.splitext(os.path.basename(archive))[0]
        dest = os.path.join(plugins_root, name)
        if os.path.exists(dest):
            return "插件已存在：" + name
        try:
            with zipfile.ZipFile(archive) as zf:
                zf.extractall(dest)
        except Exception as exc:
            logger.exception("Failed to extract plugin %s", archive)
            return "解压失败：" + str(exc)
        if not os.path.isfile(os.path.join(dest, "plugin.py")):
            shutil.rmtree(dest, ignore_errors=True)
            return "压缩包不是有效的插件（缺少 plugin.py）"
        self.load()
        return "OK:" + name

    @Slot(str, result=str)
    def removePlugin(self, compId: str) -> str:
        plugin = self._by_id.get(compId)
        if not plugin:
            return "插件不存在"
        plugin_dir = plugin.plugin_dir
        if not plugin_dir or not os.path.isdir(plugin_dir):
            return "无法定位插件目录"
        try:
            shutil.rmtree(plugin_dir)
        except Exception as exc:
            logger.exception("Failed to remove plugin %s", compId)
            return "卸载失败：" + str(exc)
        cses = self._context.get("csesParser")
        if cses is not None:
            try:
                order = list(cses.property("componentOrder") or [])
                if compId in order:
                    cses.setComponentOrder([c for c in order if c != compId])
            except Exception:
                logger.exception("Failed to clean componentOrder for %s", compId)
        self.load()
        return ""

    @Slot()
    def reload(self) -> None:
        self.load()
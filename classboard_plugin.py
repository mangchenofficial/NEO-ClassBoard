from __future__ import annotations

import json
import os
from typing import Any, Optional

from PySide6.QtCore import QObject, QUrl, Signal, Slot


class ClassBoardPlugin(QObject):
    """Abstract base class for ClassBoard plugins.

    A plugin contributes a QML component that is dynamically loaded into the
    main widget's component row, alongside the built-in ``time`` / ``classlist``
    / ``nextclass`` components.

    To create a plugin, subclass this class, set the ``PLUGIN_*`` class
    attributes, and place the module as ``plugin.py`` inside a subdirectory of
    the application's ``plugins`` folder. The :class:`PluginManager` discovers
    and instantiates it automatically.
    """

    PLUGIN_ID: str = ""
    PLUGIN_NAME: str = ""
    PLUGIN_VERSION: str = "1.0"
    PLUGIN_AUTHOR: str = ""
    PLUGIN_DESCRIPTION: str = ""
    PLUGIN_QML: str = ""
    PLUGIN_ICON: str = ""
    PREFERRED_WIDTH: int = 0
    FILL_WIDTH: bool = False
    PLUGIN_SETTINGS_QML: str = ""

    settingsChanged = Signal()

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._context: dict = {}
        self._plugin_dir: str = ""
        self._settings: dict = {}
        self._settings_path: str = ""

    def set_context(self, context: dict, plugin_dir: str) -> None:
        self._context = context
        self._plugin_dir = plugin_dir
        self._settings_path = os.path.join(plugin_dir, "settings.json")
        self._load_settings()

    @property
    def plugin_dir(self) -> str:
        return self._plugin_dir

    @property
    def context(self) -> dict:
        return self._context

    def qml_url(self) -> str:
        if not self.PLUGIN_QML:
            return ""
        path = os.path.join(self._plugin_dir, self.PLUGIN_QML)
        return QUrl.fromLocalFile(path).toString()

    def icon_url(self) -> str:
        if not self.PLUGIN_ICON:
            return ""
        path = os.path.join(self._plugin_dir, self.PLUGIN_ICON)
        if not os.path.exists(path):
            return ""
        return QUrl.fromLocalFile(path).toString()

    def settings_qml_url(self) -> str:
        if not self.PLUGIN_SETTINGS_QML:
            return ""
        path = os.path.join(self._plugin_dir, self.PLUGIN_SETTINGS_QML)
        return QUrl.fromLocalFile(path).toString()

    def metadata(self) -> dict:
        return {
            "compId": self.PLUGIN_ID,
            "name": self.PLUGIN_NAME or self.PLUGIN_ID,
            "version": self.PLUGIN_VERSION,
            "author": self.PLUGIN_AUTHOR,
            "description": self.PLUGIN_DESCRIPTION,
            "icon": self.icon_url(),
            "qmlUrl": self.qml_url(),
            "pluginDir": self._plugin_dir,
            "preferredWidth": int(self.PREFERRED_WIDTH),
            "fillWidth": bool(self.FILL_WIDTH),
            "hasSettings": len(self.settings()) > 0,
            "settingsQmlUrl": self.settings_qml_url(),
        }

    def settings(self) -> list:
        """Override to declare plugin settings.

        Each item is a dict describing a setting field:
            {
                "key": "fontSize",            # unique key
                "label": "字体大小",           # display label
                "type": "int",                # int|double|string|bool|choice
                "default": 14,                # default value
                "min": 8, "max": 32,          # optional bounds (int/double)
                "options": [                  # required for "choice"
                    {"value": "a", "label": "选项 A"},
                ],
            }
        """
        return []

    def _load_settings(self) -> None:
        try:
            if os.path.exists(self._settings_path):
                with open(self._settings_path, "r", encoding="utf-8") as f:
                    self._settings = json.load(f)
        except Exception:
            self._settings = {}

    def _save_settings(self) -> None:
        try:
            with open(self._settings_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

    @Slot(result="QVariant")
    def settingsSchema(self) -> list:
        schema = self.settings()
        result = []
        for s in schema:
            item = dict(s)
            key = item.get("key", "")
            if key not in self._settings:
                self._settings[key] = item.get("default")
            item["value"] = self._settings.get(key, item.get("default"))
            result.append(item)
        return result

    @Slot(str, result="QVariant")
    def getSetting(self, key: str) -> Any:
        schema = {s.get("key"): s for s in self.settings()}
        spec = schema.get(key, {})
        return self._settings.get(key, spec.get("default"))

    @Slot(str, "QVariant")
    def setSetting(self, key: str, value: Any) -> None:
        self._settings[key] = value
        self._save_settings()
        self.settingsChanged.emit()

    def initialize(self) -> None:
        """Called once after the plugin is loaded. Override to register QML
        types, create singletons, etc."""

    def finalize(self) -> None:
        """Called before the plugin is unloaded. Override to clean up."""
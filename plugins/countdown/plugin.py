import json
import os
from datetime import date

from PySide6.QtCore import QObject, Property, Signal, Slot, QDate

from classboard_plugin import ClassBoardPlugin


class CountdownStore(QObject):
    """Manages countdown target dates and labels, persisted to JSON."""

    targetsChanged = Signal()

    def __init__(self, plugin_dir: str, parent=None) -> None:
        super().__init__(parent)
        self._plugin_dir = plugin_dir
        self._config_path = os.path.join(plugin_dir, "config.json")
        self._targets: list = []
        self._load()

    def _load(self) -> None:
        try:
            if os.path.exists(self._config_path):
                with open(self._config_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self._targets = data.get("targets", [])
        except Exception:
            self._targets = []

    def _save(self) -> None:
        try:
            with open(self._config_path, "w", encoding="utf-8") as f:
                json.dump({"targets": self._targets}, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

    @Property(list, notify=targetsChanged)
    def targets(self) -> list:
        today = date.today()
        result = []
        for t in self._targets:
            try:
                y, m, d = t["date"].split("-")
                target_date = date(int(y), int(m), int(d))
                days = (target_date - today).days
                result.append({
                    "label": t.get("label", ""),
                    "date": t["date"],
                    "days": days,
                    "past": days < 0,
                })
            except Exception:
                continue
        result.sort(key=lambda x: x["days"])
        return result

    @Slot(str, str, result=bool)
    def addTarget(self, label: str, dateStr: str) -> bool:
        try:
            y, m, d = dateStr.split("-")
            date(int(y), int(m), int(d))
        except Exception:
            return False
        self._targets.append({"label": label, "date": dateStr})
        self._save()
        self.targetsChanged.emit()
        return True

    @Slot(int)
    def removeTarget(self, index: int) -> None:
        if 0 <= index < len(self._targets):
            self._targets.pop(index)
            self._save()
            self.targetsChanged.emit()

    @Slot(result=str)
    def todayStr(self) -> str:
        return date.today().isoformat()

    @Slot(str, result=int)
    def daysUntil(self, dateStr: str) -> int:
        try:
            y, m, d = dateStr.split("-")
            target_date = date(int(y), int(m), int(d))
            return (target_date - date.today()).days
        except Exception:
            return 0

    @Slot()
    def refresh(self) -> None:
        self.targetsChanged.emit()


class CountdownPlugin(ClassBoardPlugin):
    PLUGIN_ID = "countdown"
    PLUGIN_NAME = "倒计日"
    PLUGIN_VERSION = "1.0"
    PLUGIN_AUTHOR = "NEO ClassBoard"
    PLUGIN_DESCRIPTION = "倒计日组件，添加重要日期并实时显示剩余天数。"
    PLUGIN_QML = "CountdownWidget.qml"
    PLUGIN_SETTINGS_QML = "CountdownSettingsWidget.qml"
    PREFERRED_WIDTH = 96
    FILL_WIDTH = False

    def settings(self) -> list:
        return [
            {
                "key": "colorScheme",
                "label": "配色",
                "type": "choice",
                "default": "tertiary",
                "options": [
                    {"value": "tertiary", "label": "青色"},
                    {"value": "primary", "label": "蓝色"},
                    {"value": "secondary", "label": "紫色"},
                ],
            },
        ]

    def initialize(self) -> None:
        self._store = CountdownStore(self.plugin_dir, parent=self)

    @Property("QVariant", constant=True)
    def store(self):
        return self._store
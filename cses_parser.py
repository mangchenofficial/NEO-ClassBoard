import os
import sys
from datetime import datetime

from PySide6.QtCore import (
    QObject, Signal, Slot, Property, QTimer, QDate,
    QDateTime, QStandardPaths, QCoreApplication, QUrl, Qt,
)
from PySide6.QtWidgets import QFileDialog, QMessageBox
from PySide6.QtGui import QGuiApplication
from PySide6.QtMultimedia import QSoundEffect

LIGHT_COLORS = {
    "primary": "#6750A4", "onPrimaryColor": "#FFFFFF",
    "primaryContainer": "#EADDFF", "onPrimaryContainerColor": "#21005D",
    "secondary": "#625B71", "onSecondaryColor": "#FFFFFF",
    "secondaryContainer": "#E8DEF8", "onSecondaryContainerColor": "#1D192B",
    "tertiary": "#7D5260", "onTertiaryColor": "#FFFFFF",
    "tertiaryContainer": "#FFD8E4", "onTertiaryContainerColor": "#31111D",
    "error": "#B3261E", "onErrorColor": "#FFFFFF",
    "errorContainer": "#F9DEDC", "onErrorContainerColor": "#410E0B",
    "background": "#FFFBFE", "onBackgroundColor": "#1C1B1F",
    "surface": "#FFFBFE", "onSurfaceColor": "#1C1B1F",
    "surfaceVariant": "#E7E0EC", "onSurfaceVariantColor": "#49454F",
    "outline": "#79747E", "outlineVariant": "#CAC4D0",
    "shadow": "#000000", "scrim": "#000000",
    "inverseSurface": "#313033", "inverseOnSurface": "#F4EFF4",
    "inversePrimary": "#D0BCFF",
    "surfaceDim": "#DED8E1", "surfaceBright": "#FEF7FF",
    "surfaceContainerLowest": "#FFFFFF", "surfaceContainerLow": "#F7F2FA",
    "surfaceContainer": "#F3EDF7", "surfaceContainerHigh": "#ECE6F0",
    "surfaceContainerHighest": "#E6E0E9",
}

DARK_COLORS = {
    "primary": "#D0BCFF", "onPrimaryColor": "#381E72",
    "primaryContainer": "#4F378B", "onPrimaryContainerColor": "#EADDFF",
    "secondary": "#CCC2DC", "onSecondaryColor": "#332D41",
    "secondaryContainer": "#4A4458", "onSecondaryContainerColor": "#E8DEF8",
    "tertiary": "#EFB8C8", "onTertiaryColor": "#492532",
    "tertiaryContainer": "#633B48", "onTertiaryContainerColor": "#FFD8E4",
    "error": "#F2B8B5", "onErrorColor": "#601410",
    "errorContainer": "#8C1D18", "onErrorContainerColor": "#F9DEDC",
    "background": "#1C1B1F", "onBackgroundColor": "#E6E1E5",
    "surface": "#1C1B1F", "onSurfaceColor": "#E6E1E5",
    "surfaceVariant": "#49454F", "onSurfaceVariantColor": "#CAC4D0",
    "outline": "#938F99", "outlineVariant": "#49454F",
    "shadow": "#000000", "scrim": "#000000",
    "inverseSurface": "#E6E0E9", "inverseOnSurface": "#322F35",
    "inversePrimary": "#6750A4",
    "surfaceDim": "#141218", "surfaceBright": "#3B383E",
    "surfaceContainerLowest": "#0F0D13", "surfaceContainerLow": "#1C1B1F",
    "surfaceContainer": "#211F26", "surfaceContainerHigh": "#2B2930",
    "surfaceContainerHighest": "#36343B",
}


def _data_dir():
    path = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.AppDataLocation)
    os.makedirs(path, exist_ok=True)
    return path


def _saved_path():
    return os.path.join(_data_dir(), "schedule.yml")


def _config_path():
    return os.path.join(_data_dir(), "config.ini")


def _swaps_file():
    return os.path.join(_data_dir(), "swaps.ini")


def time_to_seconds(time_str: str) -> int:
    t = time_str.strip()
    negative = t.startswith('-')
    if negative:
        t = t[1:]
    days = 0
    dot_pos = t.find('.')
    if dot_pos >= 0:
        days = int(t[:dot_pos])
        t = t[dot_pos + 1:]
    parts = t.split(':')
    if len(parts) < 2:
        return 0
    total = ((days * 24 + int(parts[0])) * 60 + int(parts[1])) * 60 + (int(parts[2]) if len(parts) > 2 else 0)
    return -total if negative else total


def _parse_bool(value, default=False):
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    return str(value).lower() in ('true', '1', 'yes', 'on')


def _parse_int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _parse_float(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


class _YamlNode:
    __slots__ = ('indent', 'key', 'value', 'is_list')

    def __init__(self, indent, key, value, is_list):
        self.indent = indent
        self.key = key
        self.value = value
        self.is_list = is_list


def _tokenize_yaml(content: str):
    nodes = []
    for raw_line in content.split('\n'):
        stripped = raw_line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(' '))
        is_list = stripped.startswith('- ')
        trimmed = stripped[2:].strip() if is_list else stripped
        colon_pos = -1
        for k, c in enumerate(trimmed):
            if c == ':' and (k + 1 >= len(trimmed) or trimmed[k + 1] == ' '):
                colon_pos = k
                break
        if colon_pos >= 0:
            key = trimmed[:colon_pos].strip()
            value = trimmed[colon_pos + 1:].strip()
            if value == "null":
                value = ""
            elif value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
        else:
            key = trimmed
            value = ""
        nodes.append(_YamlNode(indent, key, value, is_list))
    return nodes


class CsesParser(QObject):
    filePathChanged = Signal()
    subjectsChanged = Signal()
    schedulesChanged = Signal()
    loadedChanged = Signal()
    notificationChanged = Signal()
    timeOffsetChanged = Signal()
    rescheduleDayChanged = Signal()
    classSwapsChanged = Signal()
    preparationTimeChanged = Signal()
    currentWeekChanged = Signal()
    hideInClassChanged = Signal()
    miniModeChanged = Signal()
    hoverFadeChanged = Signal()
    alwaysOnBottomChanged = Signal()
    widgetScaleChanged = Signal()
    widgetOpacityChanged = Signal()
    fontFamilyChanged = Signal()
    notificationSoundChanged = Signal()
    soundVolumeChanged = Signal()
    hideOnMaximizedChanged = Signal()
    hideOnFullscreenChanged = Signal()
    soundFilePathChanged = Signal()
    colorSchemeChanged = Signal()
    componentOrderChanged = Signal()
    componentVisibilityChanged = Signal()
    componentRowsChanged = Signal()
    classChanged = Signal(str, str)
    preparationBell = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._file_path = ""
        self._subjects = []
        self._schedules = []
        self._loaded = False
        self._notification_text = ""
        self._time_offset = 0
        self._last_notified_index = -1
        self._reschedule_day = 0
        self._class_swaps = {}
        self._preparation_time = 2
        self._last_prep_notified_index = -1
        self._current_week = 0
        self._hide_in_class = False
        self._mini_mode = False
        self._hover_fade = False
        self._always_on_bottom = False
        self._widget_scale = 1.0
        self._widget_opacity = 1.0
        self._font_family = ""
        self._notification_sound = True
        self._sound_volume = 0.7
        self._hide_on_maximized = False
        self._hide_on_fullscreen = False
        self._is_dark_theme = False
        self._sound_file_path = os.path.join(_data_dir(), "notification.wav")
        self._component_order = [["time", "classlist", "nextclass"]]
        self._component_visibility = {}
        self._component_rows = 1
        self._sound_effect = QSoundEffect(self)
        self._sound_effect.setVolume(self._sound_volume)

        self._load_saved()
        self._load_config()
        self._load_swaps()

        app = QGuiApplication.instance()
        if app:
            style_hints = app.styleHints()
            self._is_dark_theme = style_hints.colorScheme() == Qt.ColorScheme.Dark
            style_hints.colorSchemeChanged.connect(self._on_color_scheme_changed)

        self._notify_timer = QTimer(self)
        self._notify_timer.setInterval(1000)
        self._notify_timer.timeout.connect(self._check_notifications)
        self._notify_timer.start()

    def _on_color_scheme_changed(self, scheme):
        self.setIsDarkTheme(scheme == Qt.ColorScheme.Dark)

    # ── Properties ──

    @Property(str, notify=filePathChanged)
    def filePath(self): return self._file_path

    def setFilePath(self, path: str):
        if self._file_path != path:
            self._file_path = path
            self.filePathChanged.emit()

    @Property(list, notify=subjectsChanged)
    def subjects(self): return self._subjects

    @Property(list, notify=schedulesChanged)
    def schedules(self): return self._schedules

    @Property(bool, notify=loadedChanged)
    def loaded(self): return self._loaded

    def _set_loaded(self, value: bool):
        if self._loaded != value:
            self._loaded = value
            self.loadedChanged.emit()

    @Property(str, notify=notificationChanged)
    def notificationText(self): return self._notification_text

    def getTimeOffset(self): return self._time_offset

    def setTimeOffset(self, offset: int):
        if self._time_offset != offset:
            self._time_offset = offset
            self.timeOffsetChanged.emit()
            self._save_config()

    timeOffset = Property(int, getTimeOffset, setTimeOffset, notify=timeOffsetChanged)

    @Property(int, notify=rescheduleDayChanged)
    def rescheduleDay(self): return self._reschedule_day

    def setRescheduleDay(self, day: int):
        if self._reschedule_day != day:
            self._reschedule_day = day
            self.rescheduleDayChanged.emit()
            self.loadedChanged.emit()
            self._save_config()

    @Property(dict, notify=classSwapsChanged)
    def classSwaps(self): return self._class_swaps

    def getPreparationTime(self): return self._preparation_time

    def setPreparationTime(self, minutes: int):
        if self._preparation_time != minutes:
            self._preparation_time = minutes
            self.preparationTimeChanged.emit()
            self._save_config()

    preparationTime = Property(int, getPreparationTime, setPreparationTime, notify=preparationTimeChanged)

    def getCurrentWeek(self): return self._current_week

    def setCurrentWeek(self, week: int):
        if self._current_week != week:
            self._current_week = week
            self.currentWeekChanged.emit()
            self.loadedChanged.emit()
            self._save_config()

    currentWeek = Property(int, getCurrentWeek, setCurrentWeek, notify=currentWeekChanged)

    def getHideInClass(self): return self._hide_in_class

    def setHideInClass(self, val: bool):
        if self._hide_in_class != val:
            self._hide_in_class = val
            self.hideInClassChanged.emit()
            self._save_config()

    hideInClass = Property(bool, getHideInClass, setHideInClass, notify=hideInClassChanged)

    def getMiniMode(self): return self._mini_mode

    def setMiniMode(self, val: bool):
        if self._mini_mode != val:
            self._mini_mode = val
            self.miniModeChanged.emit()
            self._save_config()

    miniMode = Property(bool, getMiniMode, setMiniMode, notify=miniModeChanged)

    def getHoverFade(self): return self._hover_fade

    def setHoverFade(self, val: bool):
        if self._hover_fade != val:
            self._hover_fade = val
            self.hoverFadeChanged.emit()
            self._save_config()

    hoverFade = Property(bool, getHoverFade, setHoverFade, notify=hoverFadeChanged)

    def getAlwaysOnBottom(self): return self._always_on_bottom

    def setAlwaysOnBottom(self, val: bool):
        if self._always_on_bottom != val:
            self._always_on_bottom = val
            self.alwaysOnBottomChanged.emit()
            self._save_config()

    alwaysOnBottom = Property(bool, getAlwaysOnBottom, setAlwaysOnBottom, notify=alwaysOnBottomChanged)

    def getWidgetScale(self): return self._widget_scale

    def setWidgetScale(self, val: float):
        if abs(self._widget_scale - val) >= 1e-6:
            self._widget_scale = val
            self.widgetScaleChanged.emit()
            self._save_config()

    widgetScale = Property(float, getWidgetScale, setWidgetScale, notify=widgetScaleChanged)

    def getWidgetOpacity(self): return self._widget_opacity

    def setWidgetOpacity(self, val: float):
        if abs(self._widget_opacity - val) >= 1e-6:
            self._widget_opacity = val
            self.widgetOpacityChanged.emit()
            self._save_config()

    widgetOpacity = Property(float, getWidgetOpacity, setWidgetOpacity, notify=widgetOpacityChanged)

    def getFontFamily(self): return self._font_family if self._font_family else "MiSans"

    def setFontFamily(self, val: str):
        if self._font_family != val:
            self._font_family = val
            self.fontFamilyChanged.emit()
            self._save_config()

    fontFamily = Property(str, getFontFamily, setFontFamily, notify=fontFamilyChanged)

    def getNotificationSound(self): return self._notification_sound

    def setNotificationSound(self, val: bool):
        if self._notification_sound != val:
            self._notification_sound = val
            self.notificationSoundChanged.emit()
            self._save_config()

    notificationSound = Property(bool, getNotificationSound, setNotificationSound, notify=notificationSoundChanged)

    def getSoundVolume(self): return self._sound_volume

    def setSoundVolume(self, val: float):
        if abs(self._sound_volume - val) >= 1e-6:
            self._sound_volume = val
            self._sound_effect.setVolume(val)
            self.soundVolumeChanged.emit()
            self._save_config()

    soundVolume = Property(float, getSoundVolume, setSoundVolume, notify=soundVolumeChanged)

    def getHideOnMaximized(self): return self._hide_on_maximized

    def setHideOnMaximized(self, val: bool):
        if self._hide_on_maximized != val:
            self._hide_on_maximized = val
            self.hideOnMaximizedChanged.emit()
            self._save_config()

    hideOnMaximized = Property(bool, getHideOnMaximized, setHideOnMaximized, notify=hideOnMaximizedChanged)

    def getHideOnFullscreen(self): return self._hide_on_fullscreen

    def setHideOnFullscreen(self, val: bool):
        if self._hide_on_fullscreen != val:
            self._hide_on_fullscreen = val
            self.hideOnFullscreenChanged.emit()
            self._save_config()

    hideOnFullscreen = Property(bool, getHideOnFullscreen, setHideOnFullscreen, notify=hideOnFullscreenChanged)

    @Property(str, notify=soundFilePathChanged)
    def soundFilePath(self): return self._sound_file_path

    def setSoundFilePath(self, val: str):
        if self._sound_file_path != val:
            self._sound_file_path = val
            self.soundFilePathChanged.emit()
            self._save_config()

    @Property(list, notify=componentOrderChanged)
    def componentOrder(self): return self._component_order

    @Slot(list)
    def setComponentOrder(self, order: list):
        if self._component_order != order:
            self._component_order = order
            self.componentOrderChanged.emit()
            self._save_config()

    @Property(int, notify=componentRowsChanged)
    def componentRows(self): return len(self._component_order)

    @Slot(int)
    def setComponentRows(self, rows: int):
        r = max(1, min(5, rows))
        current = len(self._component_order)
        if r == current:
            return
        if r > current:
            for _ in range(r - current):
                self._component_order.append([])
        else:
            for row in self._component_order[r:]:
                self._component_order[r - 1].extend(row)
            self._component_order = self._component_order[:r]
        self._component_rows = r
        self.componentRowsChanged.emit()
        self.componentOrderChanged.emit()
        self._save_config()

    @Property(bool, notify=colorSchemeChanged)
    def isDarkTheme(self): return self._is_dark_theme

    def setIsDarkTheme(self, dark: bool):
        if self._is_dark_theme != dark:
            self._is_dark_theme = dark
            self.colorSchemeChanged.emit()

    @Property(dict, notify=colorSchemeChanged)
    def colorScheme(self):
        return DARK_COLORS if self._is_dark_theme else LIGHT_COLORS

    # ── Slots ──

    @Slot(int, int)
    def swapClasses(self, index_a: int, index_b: int):
        today_classes = self.getTodayClassesRaw()
        if index_a < 0 or index_a >= len(today_classes) or index_b < 0 or index_b >= len(today_classes):
            return
        cls_a = today_classes[index_a]
        cls_b = today_classes[index_b]
        self._class_swaps[str(index_a)] = cls_b.get("subject", "")
        self._class_swaps[str(index_b)] = cls_a.get("subject", "")
        self.classSwapsChanged.emit()
        self.loadedChanged.emit()
        self._save_swaps()

    @Slot(int, str)
    def replaceClass(self, index: int, new_subject: str):
        today_classes = self.getTodayClassesRaw()
        if index < 0 or index >= len(today_classes):
            return
        self._class_swaps[str(index)] = new_subject
        self.classSwapsChanged.emit()
        self.loadedChanged.emit()
        self._save_swaps()

    @Slot()
    def clearSwaps(self):
        self._class_swaps.clear()
        self.classSwapsChanged.emit()
        self.loadedChanged.emit()
        self._save_swaps()

    @Slot(result=bool)
    def hasPendingSwaps(self):
        return bool(self._class_swaps)

    @Slot(result=str)
    def swapsSummary(self):
        if not self._class_swaps:
            return ""
        lines = [f"Class {int(k) + 1}: {v}" for k, v in self._class_swaps.items()]
        return "\n".join(lines)

    @Slot()
    def playNotificationSound(self):
        if self._notification_sound:
            self._play_sound()

    @Slot()
    def testNotificationSound(self):
        self._play_sound()

    def _play_sound(self):
        path = self._sound_file_path
        if os.path.exists(path):
            self._sound_effect.setSource(QUrl.fromLocalFile(path))
            self._sound_effect.play()

    @Slot(int, int)
    def moveComponent(self, from_idx: int, to_idx: int):
        n = len(self._component_order)
        if from_idx < 0 or from_idx >= n or to_idx < 0 or to_idx >= n:
            return
        item = self._component_order.pop(from_idx)
        self._component_order.insert(to_idx, item)
        self.componentOrderChanged.emit()
        self._save_config()

    @Slot(str, result=bool)
    def isComponentVisible(self, comp_id: str):
        return self._component_visibility.get(comp_id, True)

    @Slot(str, bool)
    def setComponentVisible(self, comp_id: str, visible: bool):
        self._component_visibility[comp_id] = visible
        self.componentVisibilityChanged.emit()
        self._save_config()

    @Slot(str, int)
    def addComponent(self, comp_id: str, index: int = -1):
        for row in self._component_order:
            if comp_id in row:
                return
        if self._component_order:
            self._component_order[0].append(comp_id)
        else:
            self._component_order = [[comp_id]]
        self.componentOrderChanged.emit()
        self._save_config()

    @Slot(int)
    def removeComponent(self, index: int):
        flat = []
        for row in self._component_order:
            flat.extend(row)
        if 0 <= index < len(flat):
            del flat[index]
            self._component_order = [flat] if flat else [["time", "classlist", "nextclass"]]
            self.componentOrderChanged.emit()
            self._save_config()

    @Slot(int, int, int, int)
    def moveComponent(self, srcRow: int, srcIdx: int, targetRow: int, targetIdx: int):
        if srcRow < 0 or srcRow >= len(self._component_order):
            return
        if srcIdx < 0 or srcIdx >= len(self._component_order[srcRow]):
            return
        if targetRow < 0 or targetRow >= len(self._component_order):
            return
        comp_id = self._component_order[srcRow].pop(srcIdx)
        if targetIdx < 0 or targetIdx > len(self._component_order[targetRow]):
            targetIdx = len(self._component_order[targetRow])
        self._component_order[targetRow].insert(targetIdx, comp_id)
        self.componentOrderChanged.emit()
        self._save_config()

    @Slot()
    def resetComponents(self):
        self._component_order = [["time", "classlist", "nextclass"]]
        self._component_visibility.clear()
        self.componentOrderChanged.emit()
        self.componentVisibilityChanged.emit()
        self._save_config()

    @Slot(result=bool)
    def isForegroundWindowMaximized(self):
        from platform_utils import IS_WINDOWS
        if not IS_WINDOWS:
            return False
        import ctypes
        import ctypes.wintypes
        user32 = ctypes.windll.user32
        hwnd = user32.GetForegroundWindow()
        if not hwnd:
            return False
        style = user32.GetWindowLongW(hwnd, -16)  # GWL_STYLE
        return bool(style & 0x01000000)  # WS_MAXIMIZE

    @Slot(result=bool)
    def isInClassNow(self):
        if not self._loaded:
            return False
        today_classes = self.getTodayClasses()
        now = QDateTime.currentDateTime().addSecs(self._time_offset * 60)
        now_sec = now.time().hour() * 3600 + now.time().minute() * 60 + now.time().second()
        for cls in today_classes:
            if cls.get("type") == "class":
                start_sec = time_to_seconds(cls.get("start_time", ""))
                end_sec = time_to_seconds(cls.get("end_time", ""))
                ns = ((start_sec % 86400) + 86400) % 86400
                ne = ((end_sec % 86400) + 86400) % 86400
                if ns <= ne:
                    if ns <= now_sec < ne:
                        return True
                elif now_sec >= ns or now_sec < ne:
                    return True
        return False

    @Slot(result=list)
    def getTodayClassesRaw(self):
        today = self.getTodaySchedule()
        if not today:
            return []
        return today.get("classes", [])

    @Slot(int, result=list)
    def getClassesForDay(self, day: int):
        all_classes = []
        for schedule in self._schedules:
            if schedule.get("enable_day") == day:
                all_classes.extend(schedule.get("classes", []))
        all_classes.sort(key=lambda x: time_to_seconds(x.get("start_time", "")))
        return all_classes

    @Slot(result=bool)
    def importSchedule(self):
        path, _ = QFileDialog.getOpenFileName(None, "导入 CSES 课表文件", "",
                                              "CSES 文件 (*.yml *.yaml);;所有文件 (*)")
        if not path:
            return False
        if self.loadFromFile(path):
            self._save_to_data_dir(path)
            self.setFilePath(_saved_path())
            return True
        return False

    @Slot(result=str)
    def selectExportPath(self):
        path, _ = QFileDialog.getSaveFileName(None, "导出课表", "", "CSES 文件 (*.yml *.yaml)")
        return path

    @Slot(result=bool)
    def getAutoStart(self):
        from platform_utils import is_autostart_enabled
        return is_autostart_enabled()

    @Slot(bool)
    def setAutoStart(self, enabled: bool):
        from platform_utils import set_autostart
        set_autostart(enabled)

    @Slot(result=str)
    def selectSoundFile(self):
        path, _ = QFileDialog.getOpenFileName(None, "选择铃声文件", "",
                                              "音频文件 (*.wav);;所有文件 (*)")
        if path:
            self.setSoundFilePath(path)
        return path

    @Slot(dict)
    def addSubject(self, subj: dict):
        self._subjects.append(subj)
        self.subjectsChanged.emit()

    @Slot(int)
    def removeSubject(self, index: int):
        if 0 <= index < len(self._subjects):
            self._subjects.pop(index)
            self.subjectsChanged.emit()

    @Slot(int, dict)
    def addClassEntry(self, day: int, cls: dict):
        for i, schedule in enumerate(self._schedules):
            s = schedule
            if s.get("enable_day") == day:
                classes = list(s.get("classes", []))
                classes.append(cls)
                s["classes"] = classes
                self._schedules[i] = s
                self.schedulesChanged.emit()
                return
        self._schedules.append({
            "name": f"第{day}课表", "enable_day": day,
            "weeks": "all", "classes": [cls]
        })
        self.schedulesChanged.emit()

    @Slot(int, int)
    def removeClassEntry(self, day: int, index: int):
        all_classes = self.getClassesForDay(day)
        if 0 <= index < len(all_classes):
            all_classes.pop(index)
            self.updateDayClasses(day, all_classes)

    @Slot(int, list)
    def updateDayClasses(self, day: int, classes: list):
        base_name = f"第{day}课表"
        base_weeks = "all"
        found_first = False
        i = 0
        while i < len(self._schedules):
            s = self._schedules[i]
            if s.get("enable_day") == day:
                if not found_first:
                    base_name = s.get("name") or base_name
                    base_weeks = s.get("weeks") or "all"
                    s["classes"] = classes
                    self._schedules[i] = s
                    found_first = True
                    i += 1
                else:
                    self._schedules.pop(i)
            else:
                i += 1
        if not found_first:
            self._schedules.append({
                "name": base_name, "enable_day": day,
                "weeks": base_weeks, "classes": classes
            })
        self.schedulesChanged.emit()

    @Slot(str, result=bool)
    def exportToFile(self, path: str):
        content = "version: 1\n\nsubjects:\n"
        for subj in self._subjects:
            s = subj
            content += f"- name: {s.get('name', '')}\n"
            if s.get("simplified_name"):
                content += f"  simplified_name: {s['simplified_name']}\n"
            content += f"  teacher: {s.get('teacher') or 'null'}\n"
            content += f"  room: {s.get('room') or 'null'}\n"
        content += "schedules:\n"
        for schedule in self._schedules:
            s = schedule
            content += f"- name: {s.get('name', '')}\n"
            content += f"  enable_day: {s.get('enable_day', 0)}\n"
            content += f"  weeks: {s.get('weeks', 'all')}\n  classes:\n"
            for cls in s.get("classes", []):
                c = cls
                content += f"  - subject: {c.get('subject', '')}\n"
                content += f"    start_time: {c.get('start_time', '')}\n"
                content += f"    end_time: {c.get('end_time', '')}\n"
                if c.get("type") and c["type"] != "class":
                    content += f"    type: {c['type']}\n"
        try:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        except OSError:
            return False

    def _load_saved(self):
        path = _saved_path()
        if os.path.exists(path):
            self.loadFromFile(path)
            return
        default_path = os.path.join(QCoreApplication.applicationDirPath(), "..", "新课表 - 1.yaml")
        if os.path.exists(default_path):
            self.loadFromFile(default_path)
            self._save_to_data_dir(default_path)

    @Slot(str, result=bool)
    def loadFromFile(self, path: str):
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
        except OSError:
            print(f"Failed to open CSES file: {path}")
            return False
        self.setFilePath(path)
        return self._parse(content)

    def _save_to_data_dir(self, src_path: str):
        dst = _saved_path()
        if src_path == dst:
            return True
        if os.path.exists(dst):
            os.remove(dst)
        try:
            import shutil
            shutil.copy(src_path, dst)
            return True
        except OSError:
            return False

    @Slot(result=dict)
    def getTodaySchedule(self):
        if not self._loaded:
            return {}
        day_of_week = self._reschedule_day if self._reschedule_day > 0 else QDate.currentDate().dayOfWeek()
        all_classes = []
        combined = {"name": f"第{day_of_week}课表", "enable_day": day_of_week, "weeks": "all"}
        for schedule in self._schedules:
            s = schedule
            if s.get("enable_day") != day_of_week:
                continue
            weeks = s.get("weeks", "")
            include = (weeks == "all" or not weeks)
            if not include and self._current_week > 0:
                if weeks == "odd" and self._current_week % 2 == 1:
                    include = True
                elif weeks == "even" and self._current_week % 2 == 0:
                    include = True
            if include:
                all_classes.extend(s.get("classes", []))
        if not all_classes:
            return {}
        all_classes.sort(key=lambda x: time_to_seconds(x.get("start_time", "")))
        combined["classes"] = all_classes
        return combined

    @Slot(result=list)
    def getTodayClasses(self):
        today = self.getTodaySchedule()
        if not today:
            return []
        raw_classes = today.get("classes", [])
        result = []
        for i, cls in enumerate(raw_classes):
            c = dict(cls)
            if "type" not in c:
                c["type"] = "class"
            swap_key = str(i)
            if swap_key in self._class_swaps:
                c["subject"] = self._class_swaps[swap_key]
                c["swapped"] = True
            result.append(c)
        breaks = self._generate_breaks(raw_classes)
        result.extend(breaks)
        result.sort(key=lambda x: x.get("start_time", ""))
        return result

    def _generate_breaks(self, classes: list):
        breaks = []
        for i in range(len(classes) - 1):
            curr = classes[i]
            next_cls = classes[i + 1]
            curr_end = curr.get("end_time", "")
            next_start = next_cls.get("start_time", "")
            if curr_end < next_start:
                breaks.append({
                    "subject": "课间", "start_time": curr_end,
                    "end_time": next_start, "type": "break"
                })
        return breaks

    @Slot(str, result=dict)
    def getSubjectInfo(self, name: str):
        for subject in self._subjects:
            s = subject
            if s.get("name") == name or s.get("simplified_name") == name:
                return s
        return {}

    def _parse(self, content: str):
        self._subjects.clear()
        self._schedules.clear()
        nodes = _tokenize_yaml(content)
        i = 0
        while i < len(nodes):
            if nodes[i].key == "subjects" and not nodes[i].value:
                i = self._parse_subjects(nodes, i + 1)
            elif nodes[i].key == "schedules" and not nodes[i].value:
                i = self._parse_schedules(nodes, i + 1)
            else:
                i += 1
        self._set_loaded(True)
        self.subjectsChanged.emit()
        self.schedulesChanged.emit()
        return True

    def _parse_subjects(self, nodes: list, start: int):
        base_indent = nodes[start].indent
        i = start
        while i < len(nodes) and nodes[i].indent >= base_indent:
            if nodes[i].indent == base_indent and nodes[i].is_list and nodes[i].key == "name":
                subject = {"name": nodes[i].value}
                i += 1
                while i < len(nodes) and nodes[i].indent > base_indent and not nodes[i].is_list:
                    if nodes[i].key == "simplified_name":
                        subject["simplified_name"] = nodes[i].value
                    elif nodes[i].key == "teacher":
                        subject["teacher"] = nodes[i].value
                    elif nodes[i].key == "room":
                        subject["room"] = nodes[i].value
                    i += 1
                self._subjects.append(subject)
            elif nodes[i].indent == base_indent and not nodes[i].is_list:
                break
            else:
                i += 1
        return i

    def _parse_schedules(self, nodes: list, start: int):
        base_indent = nodes[start].indent
        i = start
        while i < len(nodes) and nodes[i].indent >= base_indent:
            if nodes[i].indent == base_indent and nodes[i].is_list and nodes[i].key == "name":
                schedule = {"name": nodes[i].value}
                i += 1
                while i < len(nodes) and nodes[i].indent > base_indent:
                    if not nodes[i].is_list:
                        if nodes[i].key == "enable_day":
                            schedule["enable_day"] = int(nodes[i].value)
                        elif nodes[i].key == "weeks":
                            schedule["weeks"] = nodes[i].value
                        i += 1
                    elif nodes[i].is_list and (nodes[i].key == "subject" or "subject" in nodes[i].key):
                        classes = []
                        while i < len(nodes) and nodes[i].indent > base_indent:
                            if not nodes[i].is_list and nodes[i].key in ("enable_day", "weeks"):
                                break
                            if nodes[i].is_list and nodes[i].key == "subject":
                                cls = {"subject": nodes[i].value}
                                i += 1
                                while i < len(nodes) and nodes[i].indent > base_indent and not nodes[i].is_list:
                                    if nodes[i].key in ("enable_day", "weeks"):
                                        break
                                    if nodes[i].key == "start_time":
                                        cls["start_time"] = nodes[i].value
                                    elif nodes[i].key == "end_time":
                                        cls["end_time"] = nodes[i].value
                                    elif nodes[i].key == "type":
                                        cls["type"] = nodes[i].value
                                    i += 1
                                classes.append(cls)
                            else:
                                i += 1
                        schedule["classes"] = classes
                    else:
                        i += 1
                if "enable_day" not in schedule:
                    schedule["enable_day"] = 0
                if "weeks" not in schedule:
                    schedule["weeks"] = "all"
                self._schedules.append(schedule)
            else:
                i += 1
        return i

    def _save_swaps(self):
        cfg = {
            "date": QDate.currentDate().toString(Qt.ISODate),
            "count": len(self._class_swaps),
        }
        for i, (key, value) in enumerate(self._class_swaps.items()):
            cfg[f"index{i}"] = key
            cfg[f"subject{i}"] = value
        self._write_ini(_swaps_file(), cfg)

    def _load_swaps(self):
        cfg = self._read_ini(_swaps_file())
        saved_date = cfg.get("date", "")
        if saved_date != QDate.currentDate().toString(Qt.ISODate):
            self._class_swaps.clear()
            self._write_ini(_swaps_file(), {})
            return
        count = _parse_int(cfg.get("count", 0))
        for i in range(count):
            key = cfg.get(f"index{i}", "")
            val = cfg.get(f"subject{i}", "")
            if key:
                self._class_swaps[key] = val

    def _load_config(self):
        cfg = self._read_ini(_config_path())
        self._time_offset = _parse_int(cfg.get("timeOffset"))
        self._preparation_time = _parse_int(cfg.get("preparationTime"), 2)
        self._current_week = _parse_int(cfg.get("currentWeek"))
        self._reschedule_day = _parse_int(cfg.get("rescheduleDay"))
        self._hide_in_class = _parse_bool(cfg.get("hideInClass"))
        self._mini_mode = _parse_bool(cfg.get("miniMode"))
        self._hover_fade = _parse_bool(cfg.get("hoverFade"))
        self._always_on_bottom = _parse_bool(cfg.get("alwaysOnBottom"))
        self._widget_scale = _parse_float(cfg.get("widgetScale"), 1.0)
        self._widget_opacity = _parse_float(cfg.get("widgetOpacity"), 1.0)
        self._font_family = cfg.get("fontFamily", "") or ""
        self._notification_sound = _parse_bool(cfg.get("notificationSound"), True)
        self._sound_volume = _parse_float(cfg.get("soundVolume"), 0.7)
        self._hide_on_maximized = _parse_bool(cfg.get("hideOnMaximized"))
        self._hide_on_fullscreen = _parse_bool(cfg.get("hideOnFullscreen"))
        self._sound_file_path = cfg.get("soundFilePath") or os.path.join(_data_dir(), "notification.wav")
        default_order_str = cfg.get("componentOrder", "time,classlist,nextclass")
        if "|" in default_order_str:
            self._component_order = [[x for x in row.split(",") if x] for row in default_order_str.split("|")]
        else:
            flat = [x for x in default_order_str.split(",") if x] or ["time", "classlist", "nextclass"]
            self._component_order = [flat]
        self._component_rows = len(self._component_order)
        vis_str = cfg.get("componentVisibility", "")
        if vis_str:
            for pair in vis_str.split(","):
                if ":" in pair:
                    k, v = pair.split(":", 1)
                    self._component_visibility[k] = v == "1"

    def _save_config(self):
        cfg = {
            "timeOffset": self._time_offset,
            "preparationTime": self._preparation_time,
            "currentWeek": self._current_week,
            "rescheduleDay": self._reschedule_day,
            "hideInClass": self._hide_in_class,
            "miniMode": self._mini_mode,
            "hoverFade": self._hover_fade,
            "alwaysOnBottom": self._always_on_bottom,
            "widgetScale": self._widget_scale,
            "widgetOpacity": self._widget_opacity,
            "fontFamily": self._font_family,
            "notificationSound": self._notification_sound,
            "soundVolume": self._sound_volume,
            "hideOnMaximized": self._hide_on_maximized,
            "hideOnFullscreen": self._hide_on_fullscreen,
            "soundFilePath": self._sound_file_path,
            "componentOrder": "|".join(",".join(row) for row in self._component_order),
            "componentRows": self._component_rows,
            "componentVisibility": ",".join(f"{k}:{1 if v else 0}"
                                            for k, v in self._component_visibility.items()),
        }
        self._write_ini(_config_path(), cfg)

    @staticmethod
    def _read_ini(path: str):
        result = {}
        if not os.path.exists(path):
            return result
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or line.startswith('['):
                    continue
                if '=' in line:
                    k, v = line.split('=', 1)
                    result[k.strip()] = v.strip()
        return result

    @staticmethod
    def _write_ini(path: str, data: dict):
        with open(path, 'w', encoding='utf-8') as f:
            f.write("[General]\n")
            for k, v in data.items():
                f.write(f"{k}={v}\n")

    def _check_notifications(self):
        if not self._loaded:
            return
        today_classes = self.getTodayClasses()
        now = QDateTime.currentDateTime().addSecs(self._time_offset * 60)
        now_sec = now.time().hour() * 3600 + now.time().minute() * 60 + now.time().second()
        current_idx = -1
        for i, cls in enumerate(today_classes):
            c = cls
            start_sec = time_to_seconds(c.get("start_time", ""))
            end_sec = time_to_seconds(c.get("end_time", ""))
            ns = ((start_sec % 86400) + 86400) % 86400
            ne = ((end_sec % 86400) + 86400) % 86400
            in_class = (ns <= now_sec < ne) if ns <= ne else (now_sec >= ns or now_sec < ne)
            if in_class:
                current_idx = i
                break
        if current_idx != self._last_notified_index and current_idx >= 0:
            self._last_notified_index = current_idx
            cls = today_classes[current_idx]
            subject_type = cls.get("type", "")
            subject = cls.get("subject", "")
            if subject_type == "break":
                self._notification_text = "课间休息"
            else:
                subj = self.getSubjectInfo(subject)
                name = subj.get("name", "")
                self._notification_text = f"活动: {name}" if subject_type == "activity" else f"上课: {name}"
            self.notificationChanged.emit()
            self.classChanged.emit(subject, subject_type)
            self._play_sound()

        if self._preparation_time > 0:
            raw_classes = self.getTodayClassesRaw()
            for i, cls in enumerate(raw_classes):
                c = cls
                start_sec = time_to_seconds(c.get("start_time", ""))
                ns = ((start_sec % 86400) + 86400) % 86400
                prep_sec = ns - self._preparation_time * 60
                if prep_sec < 0:
                    prep_sec += 86400
                if now_sec == prep_sec and i != self._last_prep_notified_index:
                    self._last_prep_notified_index = i
                    subj = self.getSubjectInfo(c.get("subject", ""))
                    self.preparationBell.emit(subj.get("name", ""))
                    self._play_sound()
                    break

    @Slot()
    def onImportClicked(self):
        path, _ = QFileDialog.getOpenFileName(None, "导入 CSES 课表文件", "",
                                              "CSES 文件 (*.yml *.yaml);;所有文件 (*)")
        if path:
            if self.loadFromFile(path):
                self._save_to_data_dir(path)
                self.setFilePath(_saved_path())
                QMessageBox.information(None, "成功", "课表导入成功!")
            else:
                QMessageBox.warning(None, "失败", "无法解析课表文件!")
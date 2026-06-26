"""
NEO ClassBoard - CSES 课表编辑器
独立运行: python cses_editor.py [schedule.yml]
"""
import os
import sys
import copy
from PyQt5.QtCore import QObject, Signal, Slot, Property, QUrl
from PyQt5.QtWidgets import QFileDialog, QMessageBox
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine, QmlElement

QML_IMPORT_NAME = "CsesEditor"
QML_IMPORT_MAJOR_VERSION = 1


def tokenize_yaml(content: str):
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
        nodes.append((indent, key, value, is_list))
    return nodes


def parse_yaml(content: str):
    from collections import OrderedDict
    nodes = tokenize_yaml(content)
    root = OrderedDict()
    stack = [(root, 0, None)]
    idx = 0
    while idx < len(nodes):
        indent, key, value, is_list = nodes[idx]
        while stack and stack[-1][1] >= indent:
            stack.pop()
        parent, parent_indent, parent_key = stack[-1]
        if is_list:
            if key not in parent:
                parent[key] = []
            lst = parent[key]
            if value:
                item = OrderedDict()
                item[key] = value
                idx += 1
                while idx < len(nodes):
                    ni, nk, nv, nl = nodes[idx]
                    if ni <= indent:
                        break
                    item[nk] = nv
                    idx += 1
                lst.append(item)
            else:
                item = OrderedDict()
                idx += 1
                while idx < len(nodes):
                    ni, nk, nv, nl = nodes[idx]
                    if ni <= indent:
                        break
                    item[nk] = nv
                    idx += 1
                lst.append(item)
            stack.append((item, indent, key))
        else:
            if value:
                parent[key] = value
            elif key not in parent:
                parent[key] = OrderedDict()
                stack.append((parent[key], indent, key))
            else:
                stack.append((parent[key], indent, key))
        if idx < len(nodes) and not (is_list and not value):
            pass
        idx += 1 if not is_list or value else idx
    return root


def dump_yaml(data, indent=0):
    lines = []
    prefix = "  " * indent
    if isinstance(data, dict):
        for k, v in data.items():
            if isinstance(v, (dict, list)):
                lines.append(f"{prefix}{k}:")
                lines.append(dump_yaml(v, indent + 1))
            elif v is None or v == '':
                lines.append(f"{prefix}{k}: ''")
            else:
                lines.append(f"{prefix}{k}: {v}")
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict):
                keys = list(item.keys())
                first_key = keys[0]
                first_val = item[first_key]
                lines.append(f"{prefix}- {first_key}: {first_val}")
                for k in keys[1:]:
                    v = item[k]
                    if v is None or v == '':
                        lines.append(f"{prefix}  {k}: ''")
                    else:
                        lines.append(f"{prefix}  {k}: {v}")
            else:
                lines.append(f"{prefix}- {item}")
    return "\n".join(lines)


def time_to_seconds(t: str) -> int:
    t = t.strip()
    neg = t.startswith('-')
    if neg:
        t = t[1:]
    days = 0
    dot = t.find('.')
    if dot >= 0:
        days = int(t[:dot])
        t = t[dot + 1:]
    parts = t.split(':')
    if len(parts) < 2:
        return 0
    total = ((days * 24 + int(parts[0])) * 60 + int(parts[1])) * 60 + (int(parts[2]) if len(parts) > 2 else 0)
    return -total if neg else total


def seconds_to_time(secs: int) -> str:
    neg = secs < 0
    if neg:
        secs = -secs
    h = secs // 3600
    m = (secs % 3600) // 60
    s = secs % 60
    if neg:
        return f"-{h:02d}:{m:02d}:{s:02d}"
    return f"{h:02d}:{m:02d}:{s:02d}"


@QmlElement
class CsesEditorBackend(QObject):
    filePathChanged = pyqtpyqtSignal()
    subjectsChanged = pyqtpyqtSignal()
    schedulesChanged = pyqtpyqtSignal()
    modifiedChanged = pyqtpyqtSignal()
    dayNamesChanged = pyqtpyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._file_path = ""
        self._subjects = []
        self._schedules = []
        self._modified = False
        self._day_names = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    @pyqtProperty(str, notify=filePathChanged)
    def filePath(self):
        return self._file_path

    def setFilePath(self, p):
        if self._file_path != p:
            self._file_path = p
            self.filePathChanged.emit()

    @pyqtProperty(list, notify=subjectsChanged)
    def subjects(self):
        return self._subjects

    @pyqtProperty(list, notify=schedulesChanged)
    def schedules(self):
        return self._schedules

    @pyqtProperty(bool, notify=modifiedChanged)
    def modified(self):
        return self._modified

    def _set_modified(self, v=True):
        if self._modified != v:
            self._modified = v
            self.modifiedChanged.emit()

    @pyqtProperty(list, notify=dayNamesChanged)
    def dayNames(self):
        return self._day_names

    @pyqtSlot(result=bool)
    def newFile(self):
        if self._modified:
            r = QMessageBox.question(None, "未保存", "当前文件有未保存的更改，是否继续？",
                                     QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
            if r != QMessageBox.StandardButton.Yes:
                return False
        self._file_path = ""
        self._subjects = []
        self._schedules = []
        self._modified = False
        self.subjectsChanged.emit()
        self.schedulesChanged.emit()
        self.filePathChanged.emit()
        self._set_modified(False)
        return True

    @pyqtSlot(result=bool)
    def openFile(self, path=""):
        if self._modified:
            r = QMessageBox.question(None, "未保存", "当前文件有未保存的更改，是否继续？",
                                     QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
            if r != QMessageBox.StandardButton.Yes:
                return False
        if not path:
            path, _ = QFileDialog.getOpenFileName(None, "打开 CSES 课表文件", "",
                                                  "CSES 文件 (*.yml *.yaml);;所有文件 (*)")
        if not path:
            return False
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            data = parse_yaml(content)
            self._subjects = data.get("subjects", [])
            self._schedules = data.get("schedules", [])
            for s in self._schedules:
                if "enable_day" not in s:
                    s["enable_day"] = 0
                if "weeks" not in s:
                    s["weeks"] = "all"
                if "classes" not in s:
                    s["classes"] = []
                for c in s.get("classes", []):
                    if "type" not in c:
                        c["type"] = "class"
            self._file_path = path
            self._modified = False
            self.subjectsChanged.emit()
            self.schedulesChanged.emit()
            self.filePathChanged.emit()
            self._set_modified(False)
            return True
        except Exception as e:
            QMessageBox.warning(None, "打开失败", f"无法读取文件:\n{e}")
            return False

    @pyqtSlot(result=bool)
    def saveFile(self):
        if not self._file_path:
            return self.saveAsFile()
        return self._write_file(self._file_path)

    @pyqtSlot(result=bool)
    def saveAsFile(self):
        path, _ = QFileDialog.getSaveFileName(None, "保存 CSES 课表文件", self._file_path or "schedule.yml",
                                              "CSES 文件 (*.yml *.yaml)")
        if not path:
            return False
        return self._write_file(path)

    def _write_file(self, path):
        data = {"version": 1, "subjects": self._subjects, "schedules": self._schedules}
        try:
            content = dump_yaml(data)
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            self._file_path = path
            self._modified = False
            self.filePathChanged.emit()
            self._set_modified(False)
            return True
        except Exception as e:
            QMessageBox.warning(None, "保存失败", f"无法写入文件:\n{e}")
            return False

    @pyqtSlot(str, str, str, str)
    def addSubject(self, name, simplified, teacher, room):
        subj = {"name": name, "simplified_name": simplified, "teacher": teacher, "room": room}
        self._subjects.append(subj)
        self.subjectsChanged.emit()
        self._set_modified()

    @pyqtSlot(int, str, str, str, str)
    def updateSubject(self, index, name, simplified, teacher, room):
        if 0 <= index < len(self._subjects):
            self._subjects[index] = {"name": name, "simplified_name": simplified, "teacher": teacher, "room": room}
            self.subjectsChanged.emit()
            self._set_modified()

    @pyqtSlot(int)
    def removeSubject(self, index):
        if 0 <= index < len(self._subjects):
            self._subjects.pop(index)
            self.subjectsChanged.emit()
            self._set_modified()

    @pyqtSlot(int, result="QVariantMap")
    def getSubject(self, index):
        if 0 <= index < len(self._subjects):
            return self._subjects[index]
        return {}

    @pyqtSlot(result="QVariantList")
    def getSubjectNames(self):
        return [s.get("name", "") for s in self._subjects]

    @pyqtSlot(int, str, str, str)
    def addSchedule(self, day, name, weeks):
        s = {"name": name, "enable_day": day, "weeks": weeks, "classes": []}
        self._schedules.append(s)
        self.schedulesChanged.emit()
        self._set_modified()

    @pyqtSlot(int)
    def removeSchedule(self, day):
        self._schedules = [s for s in self._schedules if s.get("enable_day") != day]
        self.schedulesChanged.emit()
        self._set_modified()

    @pyqtSlot(int, result="QVariantMap")
    def getSchedule(self, day):
        for s in self._schedules:
            if s.get("enable_day") == day:
                return s
        return {"name": self._day_names[day] if day < len(self._day_names) else f"第{day}天",
                "enable_day": day, "weeks": "all", "classes": []}

    @pyqtSlot(int, str, str)
    def updateScheduleInfo(self, day, name, weeks):
        s = self._get_or_create_schedule(day)
        s["name"] = name
        s["weeks"] = weeks
        self.schedulesChanged.emit()
        self._set_modified()

    def _get_or_create_schedule(self, day):
        for s in self._schedules:
            if s.get("enable_day") == day:
                return s
        name = self._day_names[day] if day < len(self._day_names) else f"第{day}天"
        s = {"name": name, "enable_day": day, "weeks": "all", "classes": []}
        self._schedules.append(s)
        return s

    @pyqtSlot(int, str, str, str, str)
    def addClass(self, day, subject, start_time, end_time, class_type):
        s = self._get_or_create_schedule(day)
        cls = {"subject": subject, "start_time": start_time, "end_time": end_time}
        if class_type and class_type != "class":
            cls["type"] = class_type
        s["classes"].append(cls)
        self._sort_classes(s)
        self.schedulesChanged.emit()
        self._set_modified()

    @pyqtSlot(int, int, str, str, str, str)
    def updateClass(self, day, index, subject, start_time, end_time, class_type):
        s = self._get_or_create_schedule(day)
        if 0 <= index < len(s["classes"]):
            cls = {"subject": subject, "start_time": start_time, "end_time": end_time}
            if class_type and class_type != "class":
                cls["type"] = class_type
            s["classes"][index] = cls
            self._sort_classes(s)
            self.schedulesChanged.emit()
            self._set_modified()

    @pyqtSlot(int, int)
    def removeClass(self, day, index):
        for s in self._schedules:
            if s.get("enable_day") == day:
                if 0 <= index < len(s["classes"]):
                    s["classes"].pop(index)
                    self.schedulesChanged.emit()
                    self._set_modified()
                return

    @pyqtSlot(int, int, int)
    def moveClass(self, day, from_idx, to_idx):
        for s in self._schedules:
            if s.get("enable_day") == day:
                cl = s["classes"]
                if 0 <= from_idx < len(cl) and 0 <= to_idx < len(cl):
                    item = cl.pop(from_idx)
                    cl.insert(to_idx, item)
                    self.schedulesChanged.emit()
                    self._set_modified()
                return

    def _sort_classes(self, schedule):
        schedule["classes"].sort(key=lambda c: time_to_seconds(c.get("start_time", "00:00:00")))


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("CSES Editor")
    engine = QQmlApplicationEngine()
    qml_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "CsesEditor.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(-1)
    if len(sys.argv) > 1 and os.path.isfile(sys.argv[1]):
        backend = engine.rootObjects()[0].findChild(QObject, "editorBackend")
        if backend:
            backend.openFile(sys.argv[1])
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
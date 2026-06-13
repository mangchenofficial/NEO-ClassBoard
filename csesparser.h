#ifndef CSESPARSER_H
#define CSESPARSER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QFile>
#include <QTextStream>
#include <QDate>
#include <QDir>
#include <QStandardPaths>
#include <QMessageBox>
#include <QFileDialog>
#include <algorithm>
#include <QTimer>
#include <QDateTime>
#include <QSettings>
#include <QUrl>

#ifdef Q_OS_WIN
#include <windows.h>
#include <mmsystem.h>
#endif

class CsesParser : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(QVariantList subjects READ subjects NOTIFY subjectsChanged)
    Q_PROPERTY(QVariantList schedules READ schedules NOTIFY schedulesChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY loadedChanged)
    Q_PROPERTY(QString notificationText READ notificationText NOTIFY notificationChanged)
    Q_PROPERTY(int timeOffset READ timeOffset WRITE setTimeOffset NOTIFY timeOffsetChanged)
    Q_PROPERTY(int rescheduleDay READ rescheduleDay WRITE setRescheduleDay NOTIFY rescheduleDayChanged)
    Q_PROPERTY(QVariantMap classSwaps READ classSwaps NOTIFY classSwapsChanged)
    Q_PROPERTY(int preparationTime READ preparationTime WRITE setPreparationTime NOTIFY preparationTimeChanged)
    Q_PROPERTY(int currentWeek READ currentWeek WRITE setCurrentWeek NOTIFY currentWeekChanged)
    Q_PROPERTY(bool hideInClass READ hideInClass WRITE setHideInClass NOTIFY hideInClassChanged)
    Q_PROPERTY(bool miniMode READ miniMode WRITE setMiniMode NOTIFY miniModeChanged)
    Q_PROPERTY(bool hoverFade READ hoverFade WRITE setHoverFade NOTIFY hoverFadeChanged)
    Q_PROPERTY(qreal widgetScale READ widgetScale WRITE setWidgetScale NOTIFY widgetScaleChanged)
    Q_PROPERTY(qreal widgetOpacity READ widgetOpacity WRITE setWidgetOpacity NOTIFY widgetOpacityChanged)
    Q_PROPERTY(QString fontFamily READ fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
    Q_PROPERTY(bool notificationSound READ notificationSound WRITE setNotificationSound NOTIFY notificationSoundChanged)
    Q_PROPERTY(qreal soundVolume READ soundVolume WRITE setSoundVolume NOTIFY soundVolumeChanged)
    Q_PROPERTY(bool hideOnMaximized READ hideOnMaximized WRITE setHideOnMaximized NOTIFY hideOnMaximizedChanged)
    Q_PROPERTY(bool hideOnFullscreen READ hideOnFullscreen WRITE setHideOnFullscreen NOTIFY hideOnFullscreenChanged)
    Q_PROPERTY(QString soundFilePath READ soundFilePath WRITE setSoundFilePath NOTIFY soundFilePathChanged)

public:
    explicit CsesParser(QObject *parent = nullptr) : QObject(parent), m_loaded(false), m_timeOffset(0), m_lastNotifiedIndex(-1), m_rescheduleDay(0), m_preparationTime(2), m_lastPrepNotifiedIndex(-1), m_currentWeek(0), m_hideInClass(false), m_miniMode(false), m_hoverFade(false), m_widgetScale(1.0), m_widgetOpacity(1.0), m_notificationSound(true), m_soundVolume(0.7), m_hideOnMaximized(false), m_hideOnFullscreen(false) {
        m_soundFilePath = dataDir() + "/notification.wav";
        loadSaved();
        loadConfig();
        loadSwaps();
        m_notifyTimer = new QTimer(this);
        m_notifyTimer->setInterval(1000);
        connect(m_notifyTimer, &QTimer::timeout, this, &CsesParser::checkNotifications);
        m_notifyTimer->start();
    }

    QString notificationText() const { return m_notificationText; }
    int timeOffset() const { return m_timeOffset; }
    void setTimeOffset(int offset) {
        if (m_timeOffset != offset) {
            m_timeOffset = offset;
            emit timeOffsetChanged();
            saveConfig();
        }
    }

    int rescheduleDay() const { return m_rescheduleDay; }
    void setRescheduleDay(int day) {
        if (m_rescheduleDay != day) {
            m_rescheduleDay = day;
            emit rescheduleDayChanged();
            emit loadedChanged();
            saveConfig();
        }
    }

    QVariantMap classSwaps() const { return m_classSwaps; }
    Q_INVOKABLE void swapClasses(int indexA, int indexB) {
        QVariantList todayClasses = getTodayClassesRaw();
        if (indexA < 0 || indexA >= todayClasses.size() || indexB < 0 || indexB >= todayClasses.size()) return;
        QVariantMap clsA = todayClasses[indexA].toMap();
        QVariantMap clsB = todayClasses[indexB].toMap();
        QString subjectA = clsA["subject"].toString();
        QString subjectB = clsB["subject"].toString();
        m_classSwaps[QString::number(indexA)] = subjectB;
        m_classSwaps[QString::number(indexB)] = subjectA;
        emit classSwapsChanged();
        emit loadedChanged();
        saveSwaps();
    }

    Q_INVOKABLE void replaceClass(int index, const QString &newSubject) {
        QVariantList todayClasses = getTodayClassesRaw();
        if (index < 0 || index >= todayClasses.size()) return;
        m_classSwaps[QString::number(index)] = newSubject;
        emit classSwapsChanged();
        emit loadedChanged();
        saveSwaps();
    }

    Q_INVOKABLE void clearSwaps() {
        m_classSwaps.clear();
        emit classSwapsChanged();
        emit loadedChanged();
        saveSwaps();
    }

    Q_INVOKABLE bool hasPendingSwaps() {
        return !m_classSwaps.isEmpty();
    }

    Q_INVOKABLE QString swapsSummary() {
        if (m_classSwaps.isEmpty()) return "";
        QStringList lines;
        for (auto it = m_classSwaps.begin(); it != m_classSwaps.end(); ++it) {
            lines << QString("第%1节 → %2").arg(it.key().toInt() + 1).arg(it.value().toString());
        }
        return lines.join("\n");
    }

    int preparationTime() const { return m_preparationTime; }
    void setPreparationTime(int minutes) {
        if (m_preparationTime != minutes) {
            m_preparationTime = minutes;
            emit preparationTimeChanged();
            saveConfig();
        }
    }

    int currentWeek() const { return m_currentWeek; }
    void setCurrentWeek(int week) {
        if (m_currentWeek != week) {
            m_currentWeek = week;
            emit currentWeekChanged();
            emit loadedChanged();
            saveConfig();
        }
    }

    bool hideInClass() const { return m_hideInClass; }
    void setHideInClass(bool val) {
        if (m_hideInClass != val) { m_hideInClass = val; emit hideInClassChanged(); saveConfig(); }
    }
    bool miniMode() const { return m_miniMode; }
    void setMiniMode(bool val) {
        if (m_miniMode != val) { m_miniMode = val; emit miniModeChanged(); saveConfig(); }
    }
    bool hoverFade() const { return m_hoverFade; }
    void setHoverFade(bool val) {
        if (m_hoverFade != val) { m_hoverFade = val; emit hoverFadeChanged(); saveConfig(); }
    }
    qreal widgetScale() const { return m_widgetScale; }
    void setWidgetScale(qreal val) {
        if (!qFuzzyCompare(m_widgetScale, val)) { m_widgetScale = val; emit widgetScaleChanged(); saveConfig(); }
    }
    qreal widgetOpacity() const { return m_widgetOpacity; }
    void setWidgetOpacity(qreal val) {
        if (!qFuzzyCompare(m_widgetOpacity, val)) { m_widgetOpacity = val; emit widgetOpacityChanged(); saveConfig(); }
    }
    QString fontFamily() const {
        return m_fontFamily.isEmpty() ? "MiSans" : m_fontFamily;
    }
    void setFontFamily(const QString &val) {
        if (m_fontFamily != val) { m_fontFamily = val; emit fontFamilyChanged(); saveConfig(); }
    }
    bool notificationSound() const { return m_notificationSound; }
    void setNotificationSound(bool val) {
        if (m_notificationSound != val) { m_notificationSound = val; emit notificationSoundChanged(); saveConfig(); }
    }
    qreal soundVolume() const { return m_soundVolume; }
    void setSoundVolume(qreal val) {
        if (!qFuzzyCompare(m_soundVolume, val)) { m_soundVolume = val; emit soundVolumeChanged(); saveConfig(); }
    }

    Q_INVOKABLE void playNotificationSound() {
        if (!m_notificationSound) return;
#ifdef Q_OS_WIN
        if (QFile::exists(m_soundFilePath)) {
            PlaySoundW((LPCWSTR)m_soundFilePath.utf16(), NULL, SND_FILENAME | SND_ASYNC);
        } else {
            PlaySound(L"SystemNotification", NULL, SND_ALIAS | SND_ASYNC);
        }
#endif
    }

    QString soundFilePath() const { return m_soundFilePath; }
    void setSoundFilePath(const QString &val) {
        if (m_soundFilePath != val) {
            m_soundFilePath = val;
            emit soundFilePathChanged();
            saveConfig();
        }
    }

    bool hideOnMaximized() const { return m_hideOnMaximized; }
    void setHideOnMaximized(bool val) {
        if (m_hideOnMaximized != val) { m_hideOnMaximized = val; emit hideOnMaximizedChanged(); saveConfig(); }
    }
    bool hideOnFullscreen() const { return m_hideOnFullscreen; }
    void setHideOnFullscreen(bool val) {
        if (m_hideOnFullscreen != val) { m_hideOnFullscreen = val; emit hideOnFullscreenChanged(); saveConfig(); }
    }

    Q_INVOKABLE bool isForegroundWindowMaximized() {
#ifdef Q_OS_WIN
        HWND hwnd = GetForegroundWindow();
        if (!hwnd) return false;
        RECT rect;
        GetWindowRect(hwnd, &rect);
        return (rect.left <= 0 && rect.top <= 0 &&
                rect.right >= GetSystemMetrics(SM_CXSCREEN) &&
                rect.bottom >= GetSystemMetrics(SM_CYSCREEN));
#else
        return false;
#endif
    }

    Q_INVOKABLE bool isInClassNow() {
        if (!m_loaded) return false;
        QVariantList todayClasses = getTodayClasses();
        QDateTime now = QDateTime::currentDateTime().addSecs(m_timeOffset * 60);
        int nowMinutes = now.time().hour() * 60 + now.time().minute();
        for (const auto &cls : todayClasses) {
            QVariantMap c = cls.toMap();
            if (c["type"].toString() == "class") {
                QString start = c["start_time"].toString();
                QString end = c["end_time"].toString();
                int startMin = start.split(":")[0].toInt() * 60 + start.split(":")[1].toInt();
                int endMin = end.split(":")[0].toInt() * 60 + end.split(":")[1].toInt();
                if (nowMinutes >= startMin && nowMinutes < endMin) return true;
            }
        }
        return false;
    }

    Q_INVOKABLE QVariantList getTodayClassesRaw() {
        QVariantMap today = getTodaySchedule();
        if (today.isEmpty()) return QVariantList();
        return today["classes"].toList();
    }

    Q_INVOKABLE QVariantList getClassesForDay(int day) {
        for (const auto &schedule : m_schedules) {
            QVariantMap s = schedule.toMap();
            if (s["enable_day"].toInt() == day) {
                return s["classes"].toList();
            }
        }
        return QVariantList();
    }

    void addSubject(const QVariantMap &subj) {
        m_subjects.append(subj);
        emit subjectsChanged();
    }

    void removeSubject(int index) {
        if (index >= 0 && index < m_subjects.size()) {
            m_subjects.removeAt(index);
            emit subjectsChanged();
        }
    }

    void addClassEntry(int day, const QVariantMap &cls) {
        for (int i = 0; i < m_schedules.size(); i++) {
            QVariantMap s = m_schedules[i].toMap();
            if (s["enable_day"].toInt() == day) {
                QVariantList classes = s["classes"].toList();
                classes.append(cls);
                s["classes"] = classes;
                m_schedules[i] = s;
                emit schedulesChanged();
                return;
            }
        }
        QVariantMap newSchedule;
        newSchedule["name"] = QString("周%1课表").arg(day);
        newSchedule["enable_day"] = day;
        newSchedule["weeks"] = "all";
        QVariantList classes;
        classes.append(cls);
        newSchedule["classes"] = classes;
        m_schedules.append(newSchedule);
        emit schedulesChanged();
    }

    void removeClassEntry(int day, int index) {
        for (int i = 0; i < m_schedules.size(); i++) {
            QVariantMap s = m_schedules[i].toMap();
            if (s["enable_day"].toInt() == day) {
                QVariantList classes = s["classes"].toList();
                if (index >= 0 && index < classes.size()) {
                    classes.removeAt(index);
                    s["classes"] = classes;
                    m_schedules[i] = s;
                    emit schedulesChanged();
                }
                return;
            }
        }
    }

    void updateDayClasses(int day, const QVariantList &classes) {
        for (int i = 0; i < m_schedules.size(); i++) {
            QVariantMap s = m_schedules[i].toMap();
            if (s["enable_day"].toInt() == day) {
                s["classes"] = classes;
                m_schedules[i] = s;
                emit schedulesChanged();
                return;
            }
        }
        QVariantMap newSchedule;
        newSchedule["name"] = QString("周%1课表").arg(day);
        newSchedule["enable_day"] = day;
        newSchedule["weeks"] = "all";
        newSchedule["classes"] = classes;
        m_schedules.append(newSchedule);
        emit schedulesChanged();
    }

    bool exportToFile(const QString &path) {
        QString content = "version: 1\n\nsubjects:\n";
        for (const auto &subj : m_subjects) {
            QVariantMap s = subj.toMap();
            content += "  - name: \"" + s["name"].toString() + "\"\n";
            if (s.contains("simplified_name") && !s["simplified_name"].toString().isEmpty())
                content += "    simplified_name: \"" + s["simplified_name"].toString() + "\"\n";
            if (s.contains("teacher") && !s["teacher"].toString().isEmpty())
                content += "    teacher: \"" + s["teacher"].toString() + "\"\n";
            if (s.contains("room") && !s["room"].toString().isEmpty())
                content += "    room: \"" + s["room"].toString() + "\"\n";
        }
        content += "\nschedules:\n";
        for (const auto &schedule : m_schedules) {
            QVariantMap s = schedule.toMap();
            content += "  - name: \"" + s["name"].toString() + "\"\n";
            content += "    enable_day: " + QString::number(s["enable_day"].toInt()) + "\n";
            content += "    weeks: " + s["weeks"].toString() + "\n";
            content += "    classes:\n";
            QVariantList classes = s["classes"].toList();
            for (const auto &cls : classes) {
                QVariantMap c = cls.toMap();
                content += "      - subject: \"" + c["subject"].toString() + "\"\n";
                content += "        start_time: \"" + c["start_time"].toString() + "\"\n";
                content += "        end_time: \"" + c["end_time"].toString() + "\"\n";
                if (c.contains("type") && c["type"].toString() != "class")
                    content += "        type: " + c["type"].toString() + "\n";
            }
        }
        QFile file(path);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
        QTextStream(&file) << content;
        file.close();
        return true;
    }

    QString filePath() const { return m_filePath; }
    void setFilePath(const QString &path) {
        if (m_filePath != path) {
            m_filePath = path;
            emit filePathChanged();
        }
    }

    QVariantList subjects() const { return m_subjects; }
    QVariantList schedules() const { return m_schedules; }
    bool loaded() const { return m_loaded; }

    static QString dataDir() {
        QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir().mkpath(dir);
        return dir;
    }

    static QString savedPath() {
        return dataDir() + "/schedule.yml";
    }

    void loadSaved() {
        QString path = savedPath();
        if (QFile::exists(path)) {
            loadFromFile(path);
        }
    }

    Q_INVOKABLE bool loadFromFile(const QString &path) {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            qWarning() << "Failed to open CSES file:" << path;
            return false;
        }
        QString content = QTextStream(&file).readAll();
        file.close();
        setFilePath(path);
        return parse(content);
    }

    bool saveToDataDir(const QString &srcPath) {
        QString dst = savedPath();
        if (srcPath == dst) return true;
        if (QFile::exists(dst)) QFile::remove(dst);
        return QFile::copy(srcPath, dst);
    }

    Q_INVOKABLE QVariantMap getTodaySchedule() {
        if (!m_loaded) return QVariantMap();
        int dayOfWeek = m_rescheduleDay > 0 ? m_rescheduleDay : QDate::currentDate().dayOfWeek();
        for (const auto &schedule : m_schedules) {
            QVariantMap s = schedule.toMap();
            if (s["enable_day"].toInt() == dayOfWeek) {
                QString weeks = s["weeks"].toString();
                if (weeks == "all" || weeks.isEmpty()) return s;
                if (m_currentWeek <= 0) return s;
                if (weeks == "odd" && m_currentWeek % 2 == 1) return s;
                if (weeks == "even" && m_currentWeek % 2 == 0) return s;
            }
        }
        for (const auto &schedule : m_schedules) {
            QVariantMap s = schedule.toMap();
            if (s["enable_day"].toInt() == dayOfWeek && (s["weeks"].toString() == "all" || s["weeks"].toString().isEmpty())) {
                return s;
            }
        }
        return QVariantMap();
    }

    Q_INVOKABLE QVariantList getTodayClasses() {
        QVariantMap today = getTodaySchedule();
        if (today.isEmpty()) return QVariantList();
        QVariantList rawClasses = today["classes"].toList();
        QVariantList result;
        for (int i = 0; i < rawClasses.size(); i++) {
            QVariantMap cls = rawClasses[i].toMap();
            if (!cls.contains("type")) cls["type"] = "class";
            QString swapKey = QString::number(i);
            if (m_classSwaps.contains(swapKey)) {
                cls["subject"] = m_classSwaps[swapKey].toString();
                cls["swapped"] = true;
            }
            result.append(cls);
        }
        QVariantList breaks = generateBreaks(rawClasses);
        for (const auto &b : breaks) result.append(b);
        std::sort(result.begin(), result.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap()["start_time"].toString() < b.toMap()["start_time"].toString();
        });
        return result;
    }

    QVariantList generateBreaks(const QVariantList &classes) {
        QVariantList breaks;
        for (int i = 0; i < classes.size() - 1; i++) {
            QVariantMap curr = classes[i].toMap();
            QVariantMap next = classes[i + 1].toMap();
            QString currEnd = curr["end_time"].toString();
            QString nextStart = next["start_time"].toString();
            if (currEnd < nextStart) {
                QVariantMap brk;
                brk["subject"] = "课间";
                brk["start_time"] = currEnd;
                brk["end_time"] = nextStart;
                brk["type"] = "break";
                breaks.append(brk);
            }
        }
        return breaks;
    }

    Q_INVOKABLE QVariantMap getSubjectInfo(const QString &name) {
        for (const auto &subject : m_subjects) {
            QVariantMap s = subject.toMap();
            if (s["name"].toString() == name || s["simplified_name"].toString() == name) {
                return s;
            }
        }
        return QVariantMap();
    }

public slots:
    void onImportClicked() {
        QString path = QFileDialog::getOpenFileName(nullptr, "导入 CSES 课表文件", "",
            "CSES 文件 (*.yml *.yaml);;所有文件 (*)");
        if (!path.isEmpty()) {
            if (loadFromFile(path)) {
                saveToDataDir(path);
                setFilePath(savedPath());
                QMessageBox::information(nullptr, "成功", "课表导入成功！");
            } else {
                QMessageBox::warning(nullptr, "失败", "无法解析课表文件。");
            }
        }
    }

signals:
    void filePathChanged();
    void subjectsChanged();
    void schedulesChanged();
    void loadedChanged();
    void notificationChanged();
    void timeOffsetChanged();
    void rescheduleDayChanged();
    void classSwapsChanged();
    void preparationTimeChanged();
    void currentWeekChanged();
    void hideInClassChanged();
    void miniModeChanged();
    void hoverFadeChanged();
    void widgetScaleChanged();
    void widgetOpacityChanged();
    void fontFamilyChanged();
    void notificationSoundChanged();
    void soundVolumeChanged();
    void hideOnMaximizedChanged();
    void hideOnFullscreenChanged();
    void soundFilePathChanged();
    void classChanged(const QString &subjectName, const QString &type);
    void preparationBell(const QString &subjectName);

private:
    struct YamlNode {
        int indent;
        QString key;
        QString value;
        bool isList;
    };

    QList<YamlNode> tokenize(const QString &content) {
        QList<YamlNode> nodes;
        QStringList lines = content.split('\n');
        for (const QString &rawLine : lines) {
            if (rawLine.trimmed().isEmpty() || rawLine.trimmed().startsWith('#'))
                continue;
            int indent = 0;
            for (QChar c : rawLine) {
                if (c == ' ') indent++;
                else break;
            }
            QString trimmed = rawLine.trimmed();
            YamlNode node;
            node.indent = indent;
            node.isList = trimmed.startsWith("- ");
            if (node.isList) trimmed = trimmed.mid(2).trimmed();
            int colonPos = trimmed.indexOf(':');
            if (colonPos >= 0) {
                node.key = trimmed.left(colonPos).trimmed();
                node.value = trimmed.mid(colonPos + 1).trimmed();
                if (node.value.startsWith('"') && node.value.endsWith('"'))
                    node.value = node.value.mid(1, node.value.length() - 2);
                else if (node.value.startsWith('\'') && node.value.endsWith('\''))
                    node.value = node.value.mid(1, node.value.length() - 2);
            } else {
                node.key = trimmed;
                node.value = "";
            }
            nodes.append(node);
        }
        return nodes;
    }

    bool parse(const QString &content) {
        m_subjects.clear();
        m_schedules.clear();

        QList<YamlNode> nodes = tokenize(content);
        int i = 0;
        while (i < nodes.size()) {
            if (nodes[i].key == "subjects" && nodes[i].value.isEmpty()) {
                i = parseSubjects(nodes, i + 1);
            } else if (nodes[i].key == "schedules" && nodes[i].value.isEmpty()) {
                i = parseSchedules(nodes, i + 1);
            } else {
                i++;
            }
        }

        m_loaded = true;
        emit subjectsChanged();
        emit schedulesChanged();
        emit loadedChanged();
        return true;
    }

    int parseSubjects(const QList<YamlNode> &nodes, int start) {
        int baseIndent = nodes[start].indent;
        int i = start;
        while (i < nodes.size() && nodes[i].indent >= baseIndent) {
            if (nodes[i].indent == baseIndent && nodes[i].isList && nodes[i].key == "name") {
                QVariantMap subject;
                subject["name"] = nodes[i].value;
                i++;
                while (i < nodes.size() && nodes[i].indent > baseIndent && !nodes[i].isList) {
                    if (nodes[i].key == "simplified_name") subject["simplified_name"] = nodes[i].value;
                    else if (nodes[i].key == "teacher") subject["teacher"] = nodes[i].value;
                    else if (nodes[i].key == "room") subject["room"] = nodes[i].value;
                    i++;
                }
                m_subjects.append(subject);
            } else {
                i++;
            }
        }
        return i;
    }

    int parseSchedules(const QList<YamlNode> &nodes, int start) {
        int baseIndent = nodes[start].indent;
        int i = start;
        while (i < nodes.size() && nodes[i].indent >= baseIndent) {
            if (nodes[i].indent == baseIndent && nodes[i].isList && nodes[i].key == "name") {
                QVariantMap schedule;
                schedule["name"] = nodes[i].value;
                i++;
                while (i < nodes.size() && nodes[i].indent > baseIndent) {
                    if (!nodes[i].isList) {
                        if (nodes[i].key == "enable_day") schedule["enable_day"] = nodes[i].value.toInt();
                        else if (nodes[i].key == "weeks") schedule["weeks"] = nodes[i].value;
                        i++;
                    } else if (nodes[i].key == "subject") {
                        QVariantList classes;
                        while (i < nodes.size() && nodes[i].indent > baseIndent) {
                            if (nodes[i].isList && nodes[i].key == "subject") {
                                QVariantMap cls;
                                cls["subject"] = nodes[i].value;
                                i++;
                                while (i < nodes.size() && nodes[i].indent > baseIndent && !nodes[i].isList) {
                                    if (nodes[i].key == "start_time") cls["start_time"] = nodes[i].value;
                                    else if (nodes[i].key == "end_time") cls["end_time"] = nodes[i].value;
                                    i++;
                                }
                                classes.append(cls);
                            } else {
                                i++;
                            }
                        }
                        schedule["classes"] = classes;
                    } else {
                        i++;
                    }
                }
                m_schedules.append(schedule);
            } else {
                i++;
            }
        }
        return i;
    }

    QString m_filePath;
    QVariantList m_subjects;
    QVariantList m_schedules;
    bool m_loaded;
    QString m_notificationText;
    int m_timeOffset;
    int m_lastNotifiedIndex;
    int m_rescheduleDay;
    QVariantMap m_classSwaps;
    int m_preparationTime;
    int m_lastPrepNotifiedIndex;
    int m_currentWeek;
    bool m_hideInClass;
    bool m_miniMode;
    bool m_hoverFade;
    qreal m_widgetScale;
    qreal m_widgetOpacity;
    QString m_fontFamily;
    bool m_notificationSound;
    qreal m_soundVolume;
    bool m_hideOnMaximized;
    bool m_hideOnFullscreen;
    QString m_soundFilePath;
    QTimer *m_notifyTimer;

    static QString configPath() {
        return dataDir() + "/config.ini";
    }

    static QString swapsFile() {
        return dataDir() + "/swaps.ini";
    }

    void saveSwaps() {
        QSettings cfg(swapsFile(), QSettings::IniFormat);
        cfg.setValue("date", QDate::currentDate().toString(Qt::ISODate));
        cfg.setValue("count", m_classSwaps.size());
        int i = 0;
        for (auto it = m_classSwaps.begin(); it != m_classSwaps.end(); ++it) {
            cfg.setValue(QString("index%1").arg(i), it.key());
            cfg.setValue(QString("subject%1").arg(i), it.value().toString());
            i++;
        }
        cfg.sync();
    }

    void loadSwaps() {
        QSettings cfg(swapsFile(), QSettings::IniFormat);
        QString savedDate = cfg.value("date").toString();
        if (savedDate != QDate::currentDate().toString(Qt::ISODate)) {
            m_classSwaps.clear();
            cfg.clear();
            cfg.sync();
            return;
        }
        int count = cfg.value("count", 0).toInt();
        for (int i = 0; i < count; i++) {
            QString key = cfg.value(QString("index%1").arg(i)).toString();
            QString val = cfg.value(QString("subject%1").arg(i)).toString();
            if (!key.isEmpty()) m_classSwaps[key] = val;
        }
    }

    void loadConfig() {
        QSettings cfg(configPath(), QSettings::IniFormat);
        m_timeOffset = cfg.value("timeOffset", 0).toInt();
        m_preparationTime = cfg.value("preparationTime", 2).toInt();
        m_currentWeek = cfg.value("currentWeek", 0).toInt();
        m_rescheduleDay = cfg.value("rescheduleDay", 0).toInt();
        m_hideInClass = cfg.value("hideInClass", false).toBool();
        m_miniMode = cfg.value("miniMode", false).toBool();
        m_hoverFade = cfg.value("hoverFade", false).toBool();
        m_widgetScale = cfg.value("widgetScale", 1.0).toReal();
        m_widgetOpacity = cfg.value("widgetOpacity", 1.0).toReal();
        m_fontFamily = cfg.value("fontFamily", "").toString();
        m_notificationSound = cfg.value("notificationSound", true).toBool();
        m_soundVolume = cfg.value("soundVolume", 0.7).toReal();
        m_hideOnMaximized = cfg.value("hideOnMaximized", false).toBool();
        m_hideOnFullscreen = cfg.value("hideOnFullscreen", false).toBool();
        m_soundFilePath = cfg.value("soundFilePath", dataDir() + "/notification.wav").toString();
    }

    void saveConfig() {
        QSettings cfg(configPath(), QSettings::IniFormat);
        cfg.setValue("timeOffset", m_timeOffset);
        cfg.setValue("preparationTime", m_preparationTime);
        cfg.setValue("currentWeek", m_currentWeek);
        cfg.setValue("rescheduleDay", m_rescheduleDay);
        cfg.setValue("hideInClass", m_hideInClass);
        cfg.setValue("miniMode", m_miniMode);
        cfg.setValue("hoverFade", m_hoverFade);
        cfg.setValue("widgetScale", m_widgetScale);
        cfg.setValue("widgetOpacity", m_widgetOpacity);
        cfg.setValue("fontFamily", m_fontFamily);
        cfg.setValue("notificationSound", m_notificationSound);
        cfg.setValue("soundVolume", m_soundVolume);
        cfg.setValue("hideOnMaximized", m_hideOnMaximized);
        cfg.setValue("hideOnFullscreen", m_hideOnFullscreen);
        cfg.setValue("soundFilePath", m_soundFilePath);
        cfg.sync();
    }

    void checkNotifications() {
        if (!m_loaded) return;
        QVariantList todayClasses = getTodayClasses();
        QDateTime now = QDateTime::currentDateTime().addSecs(m_timeOffset * 60);
        int nowMinutes = now.time().hour() * 60 + now.time().minute();
        int nowSeconds = now.time().second();
        int currentIdx = -1;
        for (int i = 0; i < todayClasses.size(); i++) {
            QVariantMap cls = todayClasses[i].toMap();
            QString start = cls["start_time"].toString();
            QString end = cls["end_time"].toString();
            int startMin = start.split(":")[0].toInt() * 60 + start.split(":")[1].toInt();
            int endMin = end.split(":")[0].toInt() * 60 + end.split(":")[1].toInt();
            if (nowMinutes >= startMin && nowMinutes < endMin) {
                currentIdx = i;
                break;
            }
        }
        if (currentIdx != m_lastNotifiedIndex && currentIdx >= 0) {
            m_lastNotifiedIndex = currentIdx;
            QVariantMap cls = todayClasses[currentIdx].toMap();
            QString type = cls["type"].toString();
            QString subject = cls["subject"].toString();
            if (type == "break") {
                m_notificationText = "课间休息";
            } else {
                QVariantMap subj = getSubjectInfo(subject);
                QString name = subj["name"].toString();
                m_notificationText = type == "activity" ? "活动: " + name : "上课: " + name;
            }
            emit notificationChanged();
            emit classChanged(subject, type);
            playNotificationSound();
        }

        if (m_preparationTime > 0) {
            QVariantList rawClasses = getTodayClassesRaw();
            for (int i = 0; i < rawClasses.size(); i++) {
                QVariantMap cls = rawClasses[i].toMap();
                QString start = cls["start_time"].toString();
                int startMin = start.split(":")[0].toInt() * 60 + start.split(":")[1].toInt();
                int prepMin = startMin - m_preparationTime;
                if (nowMinutes == prepMin && nowSeconds < 2 && i != m_lastPrepNotifiedIndex) {
                    m_lastPrepNotifiedIndex = i;
                    QVariantMap subj = getSubjectInfo(cls["subject"].toString());
                    emit preparationBell(subj["name"].toString());
                    playNotificationSound();
                    break;
                }
            }
        }
    }
};

#endif

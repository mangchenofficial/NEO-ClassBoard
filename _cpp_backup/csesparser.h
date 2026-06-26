#ifndef CSESPARSER_H
#define CSESPARSER_H

#include <QObject>
#include <QCoreApplication>
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
#include <QStyleHints>
#include <QGuiApplication>

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
    Q_PROPERTY(bool alwaysOnBottom READ alwaysOnBottom WRITE setAlwaysOnBottom NOTIFY alwaysOnBottomChanged)
    Q_PROPERTY(qreal widgetScale READ widgetScale WRITE setWidgetScale NOTIFY widgetScaleChanged)
    Q_PROPERTY(qreal widgetOpacity READ widgetOpacity WRITE setWidgetOpacity NOTIFY widgetOpacityChanged)
    Q_PROPERTY(QString fontFamily READ fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
    Q_PROPERTY(bool notificationSound READ notificationSound WRITE setNotificationSound NOTIFY notificationSoundChanged)
    Q_PROPERTY(qreal soundVolume READ soundVolume WRITE setSoundVolume NOTIFY soundVolumeChanged)
    Q_PROPERTY(bool hideOnMaximized READ hideOnMaximized WRITE setHideOnMaximized NOTIFY hideOnMaximizedChanged)
    Q_PROPERTY(bool hideOnFullscreen READ hideOnFullscreen WRITE setHideOnFullscreen NOTIFY hideOnFullscreenChanged)
    Q_PROPERTY(QString soundFilePath READ soundFilePath WRITE setSoundFilePath NOTIFY soundFilePathChanged)
    Q_PROPERTY(bool isDarkTheme READ isDarkTheme NOTIFY colorSchemeChanged)
    Q_PROPERTY(QVariantMap colorScheme READ colorScheme NOTIFY colorSchemeChanged)
    Q_PROPERTY(QStringList componentOrder READ componentOrder WRITE setComponentOrder NOTIFY componentOrderChanged)

public:
    explicit CsesParser(QObject *parent = nullptr) : QObject(parent), m_loaded(false), m_timeOffset(0), m_lastNotifiedIndex(-1), m_rescheduleDay(0), m_preparationTime(2), m_lastPrepNotifiedIndex(-1), m_currentWeek(0), m_hideInClass(false), m_miniMode(false), m_hoverFade(false), m_alwaysOnBottom(false), m_widgetScale(1.0), m_widgetOpacity(1.0), m_notificationSound(true), m_soundVolume(0.7), m_hideOnMaximized(false), m_hideOnFullscreen(false), m_isDarkTheme(false) {
        m_soundFilePath = dataDir() + "/notification.wav";
        loadSaved();
        loadConfig();
        loadSwaps();
        if (const QStyleHints *styleHints = QGuiApplication::styleHints()) {
            m_isDarkTheme = (styleHints->colorScheme() == Qt::ColorScheme::Dark);
            connect(styleHints, &QStyleHints::colorSchemeChanged, this, [this](Qt::ColorScheme scheme){
                setIsDarkTheme(scheme == Qt::ColorScheme::Dark);
            });
        }
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
            lines << QString("Class %1: %2").arg(it.key().toInt() + 1).arg(it.value().toString());
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
    bool alwaysOnBottom() const { return m_alwaysOnBottom; }
    void setAlwaysOnBottom(bool val) {
        if (m_alwaysOnBottom != val) { m_alwaysOnBottom = val; emit alwaysOnBottomChanged(); saveConfig(); }
    }

    Q_INVOKABLE void applyWindowZOrder(qint64 winId) {
#ifdef Q_OS_WIN
        HWND hwnd = (HWND)winId;
        if (m_alwaysOnBottom) {
            SetWindowLongPtr(hwnd, GWL_EXSTYLE, GetWindowLongPtr(hwnd, GWL_EXSTYLE) & ~WS_EX_TOPMOST);
            SetWindowPos(hwnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_FRAMECHANGED);
        } else {
            SetWindowLongPtr(hwnd, GWL_EXSTYLE, GetWindowLongPtr(hwnd, GWL_EXSTYLE) | WS_EX_TOPMOST);
            SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED);
        }
#endif
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
        playSound();
#endif
    }

    Q_INVOKABLE void testNotificationSound() {
#ifdef Q_OS_WIN
        playSound();
#endif
    }

private:
    void playSound() {
#ifdef Q_OS_WIN
        if (QFile::exists(m_soundFilePath)) {
            PlaySoundW((LPCWSTR)m_soundFilePath.utf16(), NULL, SND_FILENAME | SND_ASYNC);
        } else {
            PlaySound(L"SystemNotification", NULL, SND_ALIAS | SND_ASYNC);
        }
#endif
    }

public:

    QString soundFilePath() const { return m_soundFilePath; }
    void setSoundFilePath(const QString &val) {
        if (m_soundFilePath != val) {
            m_soundFilePath = val;
            emit soundFilePathChanged();
            saveConfig();
        }
    }

    QStringList componentOrder() const { return m_componentOrder; }
    void setComponentOrder(const QStringList &order) {
        if (m_componentOrder != order) {
            m_componentOrder = order;
            emit componentOrderChanged();
            saveConfig();
        }
    }

    QVariantMap componentVisibility() const { return m_componentVisibility; }
    void setComponentVisibility(const QVariantMap &vis) {
        if (m_componentVisibility != vis) {
            m_componentVisibility = vis;
            emit componentVisibilityChanged();
            saveConfig();
        }
    }

    Q_INVOKABLE void moveComponent(int from, int to) {
        if (from < 0 || from >= m_componentOrder.size() || to < 0 || to >= m_componentOrder.size()) return;
        m_componentOrder.move(from, to);
        emit componentOrderChanged();
        saveConfig();
    }

    Q_INVOKABLE bool isComponentVisible(const QString &id) {
        if (m_componentVisibility.contains(id))
            return m_componentVisibility[id].toBool();
        return true;
    }

    Q_INVOKABLE void setComponentVisible(const QString &id, bool visible) {
        m_componentVisibility[id] = visible;
        emit componentVisibilityChanged();
        saveConfig();
    }

    Q_INVOKABLE void addComponent(const QString &id, int position = -1) {
        if (m_componentOrder.contains(id)) return;
        if (position < 0 || position > m_componentOrder.size())
            m_componentOrder.append(id);
        else
            m_componentOrder.insert(position, id);
        emit componentOrderChanged();
        saveConfig();
    }

    Q_INVOKABLE void removeComponent(int index) {
        if (index < 0 || index >= m_componentOrder.size()) return;
        m_componentOrder.removeAt(index);
        emit componentOrderChanged();
        saveConfig();
    }

    Q_INVOKABLE void resetComponents() {
        m_componentOrder = QStringList{"time", "classlist", "nextclass"};
        emit componentOrderChanged();
        saveConfig();
    }

    bool hideOnMaximized() const { return m_hideOnMaximized; }
    void setHideOnMaximized(bool val) {
        if (m_hideOnMaximized != val) { m_hideOnMaximized = val; emit hideOnMaximizedChanged(); saveConfig(); }
    }
    bool hideOnFullscreen() const { return m_hideOnFullscreen; }
    void setHideOnFullscreen(bool val) {
        if (m_hideOnFullscreen != val) { m_hideOnFullscreen = val; emit hideOnFullscreenChanged(); saveConfig(); }
    }

    bool isDarkTheme() const { return m_isDarkTheme; }
    void setIsDarkTheme(bool dark) {
        if (m_isDarkTheme != dark) {
            m_isDarkTheme = dark;
            emit colorSchemeChanged();
        }
    }

    QVariantMap colorScheme() const {
        return m_isDarkTheme ? darkColors() : lightColors();
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
        int nowSec = now.time().hour() * 3600 + now.time().minute() * 60 + now.time().second();
        for (const auto &cls : todayClasses) {
            QVariantMap c = cls.toMap();
            if (c["type"].toString() == "class") {
                int startSec = timeToSeconds(c["start_time"].toString());
                int endSec = timeToSeconds(c["end_time"].toString());
                int normStart = ((startSec % 86400) + 86400) % 86400;
                int normEnd = ((endSec % 86400) + 86400) % 86400;
                if (normStart <= normEnd) {
                    if (nowSec >= normStart && nowSec < normEnd) return true;
                } else {
                    if (nowSec >= normStart || nowSec < normEnd) return true;
                }
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
        QVariantList allClasses;
        for (const auto &schedule : m_schedules) {
            QVariantMap s = schedule.toMap();
            if (s["enable_day"].toInt() == day) {
                allClasses.append(s["classes"].toList());
            }
        }
        std::sort(allClasses.begin(), allClasses.end(), [](const QVariant &a, const QVariant &b) {
            return timeToSeconds(a.toMap()["start_time"].toString()) < timeToSeconds(b.toMap()["start_time"].toString());
        });
        return allClasses;
    }

    Q_INVOKABLE bool importSchedule() {
        QString path = QFileDialog::getOpenFileName(nullptr, "导入 CSES 课表文件", "",
            "CSES 文件 (*.yml *.yaml);;所有文件 (*)");
        if (path.isEmpty()) return false;
        if (loadFromFile(path)) {
            saveToDataDir(path);
            setFilePath(savedPath());
            return true;
        }
        return false;
    }

    Q_INVOKABLE QString selectExportPath() {
        return QFileDialog::getSaveFileName(nullptr, "导出课表", "", "CSES 文件 (*.yml *.yaml)");
    }

    Q_INVOKABLE bool getAutoStart() {
        QSettings reg("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                       QSettings::NativeFormat);
        return reg.value("ClassBoard").isValid();
    }

    Q_INVOKABLE void setAutoStart(bool enabled) {
        QSettings r("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", QSettings::NativeFormat);
        if (enabled) r.setValue("ClassBoard", QCoreApplication::applicationFilePath().replace('/', '\\'));
        else r.remove("ClassBoard");
    }

    Q_INVOKABLE QString selectSoundFile() {
        QString path = QFileDialog::getOpenFileName(nullptr, "选择铃声文件", "",
            "音频文件 (*.wav);;所有文件 (*)");
        if (!path.isEmpty()) {
            setSoundFilePath(path);
        }
        return path;
    }

    Q_INVOKABLE void addSubject(const QVariantMap &subj) {
        m_subjects.append(subj);
        emit subjectsChanged();
    }

    Q_INVOKABLE void removeSubject(int index) {
        if (index >= 0 && index < m_subjects.size()) {
            m_subjects.removeAt(index);
            emit subjectsChanged();
        }
    }

    Q_INVOKABLE void addClassEntry(int day, const QVariantMap &cls) {
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
        newSchedule["name"] = QString("第%1课表").arg(day);
        newSchedule["enable_day"] = day;
        newSchedule["weeks"] = "all";
        QVariantList classes;
        classes.append(cls);
        newSchedule["classes"] = classes;
        m_schedules.append(newSchedule);
        emit schedulesChanged();
    }

    Q_INVOKABLE void removeClassEntry(int day, int index) {
        QVariantList allClasses = getClassesForDay(day);
        if (index < 0 || index >= allClasses.size()) return;
        allClasses.removeAt(index);
        updateDayClasses(day, allClasses);
    }

    Q_INVOKABLE void updateDayClasses(int day, const QVariantList &classes) {
        QString baseName = QString("第%1课表").arg(day);
        QString baseWeeks = "all";
        bool foundFirst = false;
        for (int i = 0; i < m_schedules.size();) {
            QVariantMap s = m_schedules[i].toMap();
            if (s["enable_day"].toInt() == day) {
                if (!foundFirst) {
                    baseName = s["name"].toString().isEmpty() ? baseName : s["name"].toString();
                    baseWeeks = s["weeks"].toString().isEmpty() ? "all" : s["weeks"].toString();
                    s["classes"] = classes;
                    m_schedules[i] = s;
                    foundFirst = true;
                    ++i;
                } else {
                    m_schedules.removeAt(i);
                }
            } else {
                ++i;
            }
        }
        if (!foundFirst) {
            QVariantMap newSchedule;
            newSchedule["name"] = baseName;
            newSchedule["enable_day"] = day;
            newSchedule["weeks"] = baseWeeks;
            newSchedule["classes"] = classes;
            m_schedules.append(newSchedule);
        }
        emit schedulesChanged();
    }

    Q_INVOKABLE bool exportToFile(const QString &path) {
        QString content = "version: 1\n\nsubjects:\n";
        for (const auto &subj : m_subjects) {
            QVariantMap s = subj.toMap();
            content += "- name: " + s["name"].toString() + "\n";
            if (s.contains("simplified_name") && !s["simplified_name"].toString().isEmpty())
                content += "  simplified_name: " + s["simplified_name"].toString() + "\n";
            content += "  teacher: " + (s.contains("teacher") && !s["teacher"].toString().isEmpty() ? s["teacher"].toString() : "null") + "\n";
            content += "  room: " + (s.contains("room") && !s["room"].toString().isEmpty() ? s["room"].toString() : "null") + "\n";
        }
        content += "schedules:\n";
        for (const auto &schedule : m_schedules) {
            QVariantMap s = schedule.toMap();
            content += "- name: " + s["name"].toString() + "\n";
            content += "  enable_day: " + QString::number(s["enable_day"].toInt()) + "\n";
            content += "  weeks: " + s["weeks"].toString() + "\n";
            content += "  classes:\n";
            QVariantList classes = s["classes"].toList();
            for (const auto &cls : classes) {
                QVariantMap c = cls.toMap();
                content += "  - subject: " + c["subject"].toString() + "\n";
                content += "    start_time: " + c["start_time"].toString() + "\n";
                content += "    end_time: " + c["end_time"].toString() + "\n";
                if (c.contains("type") && c["type"].toString() != "class")
                    content += "    type: " + c["type"].toString() + "\n";
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
            return;
        }
        QString defaultPath = QCoreApplication::applicationDirPath() + "/../新课表 - 1.yaml";
        if (QFile::exists(defaultPath)) {
            loadFromFile(defaultPath);
            saveToDataDir(defaultPath);
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

    static int timeToSeconds(const QString &timeStr) {
        QString t = timeStr.trimmed();
        bool negative = t.startsWith('-');
        if (negative) t = t.mid(1);
        int days = 0;
        int dotPos = t.indexOf('.');
        if (dotPos >= 0) {
            days = t.left(dotPos).toInt();
            t = t.mid(dotPos + 1);
        }
        QStringList parts = t.split(':');
        if (parts.size() < 2) return 0;
        int h = parts[0].toInt();
        int m = parts[1].toInt();
        int s = parts.size() > 2 ? parts[2].toInt() : 0;
        int total = ((days * 24 + h) * 60 + m) * 60 + s;
        return negative ? -total : total;
    }

    Q_INVOKABLE QVariantMap getTodaySchedule() {
        if (!m_loaded) return QVariantMap();
        int dayOfWeek = m_rescheduleDay > 0 ? m_rescheduleDay : QDate::currentDate().dayOfWeek();
        QVariantList allClasses;
        QVariantMap combined;
        combined["name"] = QString("第%1课表").arg(dayOfWeek);
        combined["enable_day"] = dayOfWeek;
        combined["weeks"] = "all";
        for (const auto &schedule : m_schedules) {
            QVariantMap s = schedule.toMap();
            if (s["enable_day"].toInt() != dayOfWeek) continue;
            QString weeks = s["weeks"].toString();
            bool include = (weeks == "all" || weeks.isEmpty());
            if (!include) {
                if (m_currentWeek <= 0) include = true;
                else if (weeks == "odd" && m_currentWeek % 2 == 1) include = true;
                else if (weeks == "even" && m_currentWeek % 2 == 0) include = true;
            }
            if (include) {
                allClasses.append(s["classes"].toList());
            }
        }
        if (allClasses.isEmpty()) return QVariantMap();
        std::sort(allClasses.begin(), allClasses.end(), [](const QVariant &a, const QVariant &b) {
            return timeToSeconds(a.toMap()["start_time"].toString()) < timeToSeconds(b.toMap()["start_time"].toString());
        });
        combined["classes"] = allClasses;
        return combined;
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
                QMessageBox::information(nullptr, "成功", "课表导入成功!");
            } else {
                QMessageBox::warning(nullptr, "失败", "无法解析课表文件!");
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
    void alwaysOnBottomChanged();
    void widgetScaleChanged();
    void widgetOpacityChanged();
    void fontFamilyChanged();
    void notificationSoundChanged();
    void soundVolumeChanged();
    void hideOnMaximizedChanged();
    void hideOnFullscreenChanged();
    void soundFilePathChanged();
    void colorSchemeChanged();
    void componentOrderChanged();
    void componentVisibilityChanged();
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
            int colonPos = -1;
            for (int k = 0; k < trimmed.size(); k++) {
                QChar c = trimmed[k];
                if (c == ':' && (k + 1 >= trimmed.size() || trimmed[k + 1] == ' ')) {
                    colonPos = k;
                    break;
                }
            }
            if (colonPos >= 0) {
                node.key = trimmed.left(colonPos).trimmed();
                node.value = trimmed.mid(colonPos + 1).trimmed();
                if (node.value == "null")
                    node.value.clear();
                else if (node.value.startsWith('"') && node.value.endsWith('"'))
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
        qDebug() << "CSES: tokens =" << nodes.size();
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
            } else if (nodes[i].indent == baseIndent && !nodes[i].isList) {
                break;
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
                    } else if (nodes[i].isList && (nodes[i].key == "subject" || nodes[i].key.contains("subject"))) {
                        QVariantList classes;
                        while (i < nodes.size() && nodes[i].indent > baseIndent) {
                            if (!nodes[i].isList && (nodes[i].key == "enable_day" || nodes[i].key == "weeks"))
                                break;
                            if (nodes[i].isList && nodes[i].key == "subject") {
                                QVariantMap cls;
                                cls["subject"] = nodes[i].value;
                                i++;
                                while (i < nodes.size() && nodes[i].indent > baseIndent && !nodes[i].isList) {
                                    if (nodes[i].key == "enable_day" || nodes[i].key == "weeks") break;
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
                if (!schedule.contains("enable_day")) schedule["enable_day"] = 0;
                if (!schedule.contains("weeks")) schedule["weeks"] = "all";
                m_schedules.append(schedule);
            } else {
                i++;
            }
        }
        return i;
    }

    static QVariantMap lightColors() {
        return {
            {"primary", "#6750A4"},
            {"onPrimaryColor", "#FFFFFF"},
            {"primaryContainer", "#EADDFF"},
            {"onPrimaryContainerColor", "#21005D"},
            {"secondary", "#625B71"},
            {"onSecondaryColor", "#FFFFFF"},
            {"secondaryContainer", "#E8DEF8"},
            {"onSecondaryContainerColor", "#1D192B"},
            {"tertiary", "#7D5260"},
            {"onTertiaryColor", "#FFFFFF"},
            {"tertiaryContainer", "#FFD8E4"},
            {"onTertiaryContainerColor", "#31111D"},
            {"error", "#B3261E"},
            {"onErrorColor", "#FFFFFF"},
            {"errorContainer", "#F9DEDC"},
            {"onErrorContainerColor", "#410E0B"},
            {"background", "#FFFBFE"},
            {"onBackgroundColor", "#1C1B1F"},
            {"surface", "#FFFBFE"},
            {"onSurfaceColor", "#1C1B1F"},
            {"surfaceVariant", "#E7E0EC"},
            {"onSurfaceVariantColor", "#49454F"},
            {"outline", "#79747E"},
            {"outlineVariant", "#CAC4D0"},
            {"shadow", "#000000"},
            {"scrim", "#000000"},
            {"surfaceDim", "#DED8E1"},
            {"surfaceBright", "#FEF7FF"},
            {"surfaceContainerLowest", "#FFFFFF"},
            {"surfaceContainerLow", "#F7F2FA"},
            {"surfaceContainer", "#F3EDF7"},
            {"surfaceContainerHigh", "#ECE6F0"},
            {"surfaceContainerHighest", "#E6E0E9"}
        };
    }

    static QVariantMap darkColors() {
        return {
            {"primary", "#D0BCFF"},
            {"onPrimaryColor", "#381E72"},
            {"primaryContainer", "#4F378B"},
            {"onPrimaryContainerColor", "#EADDFF"},
            {"secondary", "#CCC2DC"},
            {"onSecondaryColor", "#332D41"},
            {"secondaryContainer", "#4A4458"},
            {"onSecondaryContainerColor", "#E8DEF8"},
            {"tertiary", "#EFB8C8"},
            {"onTertiaryColor", "#492532"},
            {"tertiaryContainer", "#633B48"},
            {"onTertiaryContainerColor", "#FFD8E4"},
            {"error", "#F2B8B5"},
            {"onErrorColor", "#601410"},
            {"errorContainer", "#8C1D18"},
            {"onErrorContainerColor", "#F9DEDC"},
            {"background", "#1C1B1F"},
            {"onBackgroundColor", "#E6E1E5"},
            {"surface", "#1C1B1F"},
            {"onSurfaceColor", "#E6E1E5"},
            {"surfaceVariant", "#49454F"},
            {"onSurfaceVariantColor", "#CAC4D0"},
            {"outline", "#938F99"},
            {"outlineVariant", "#49454F"},
            {"shadow", "#000000"},
            {"scrim", "#000000"},
            {"surfaceDim", "#141218"},
            {"surfaceBright", "#3B383E"},
            {"surfaceContainerLowest", "#0F0D13"},
            {"surfaceContainerLow", "#1C1B1F"},
            {"surfaceContainer", "#211F26"},
            {"surfaceContainerHigh", "#2B2930"},
            {"surfaceContainerHighest", "#36343B"}
        };
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
    bool m_alwaysOnBottom;
    qreal m_widgetScale;
    qreal m_widgetOpacity;
    QString m_fontFamily;
    bool m_notificationSound;
    qreal m_soundVolume;
    bool m_hideOnMaximized;
    bool m_hideOnFullscreen;
    bool m_isDarkTheme;
    QString m_soundFilePath;
    QStringList m_componentOrder;
    QVariantMap m_componentVisibility;
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
        m_alwaysOnBottom = cfg.value("alwaysOnBottom", false).toBool();
        m_widgetScale = cfg.value("widgetScale", 1.0).toReal();
        m_widgetOpacity = cfg.value("widgetOpacity", 1.0).toReal();
        m_fontFamily = cfg.value("fontFamily", "").toString();
        m_notificationSound = cfg.value("notificationSound", true).toBool();
        m_soundVolume = cfg.value("soundVolume", 0.7).toReal();
        m_hideOnMaximized = cfg.value("hideOnMaximized", false).toBool();
        m_hideOnFullscreen = cfg.value("hideOnFullscreen", false).toBool();
        m_soundFilePath = cfg.value("soundFilePath", dataDir() + "/notification.wav").toString();
        QString defaultOrder = cfg.value("componentOrder", "time,classlist,nextclass").toString();
        m_componentOrder = defaultOrder.split(",", Qt::SkipEmptyParts);
        if (m_componentOrder.isEmpty()) m_componentOrder = QStringList{"time", "classlist", "nextclass"};
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
        cfg.setValue("alwaysOnBottom", m_alwaysOnBottom);
        cfg.setValue("widgetScale", m_widgetScale);
        cfg.setValue("widgetOpacity", m_widgetOpacity);
        cfg.setValue("fontFamily", m_fontFamily);
        cfg.setValue("notificationSound", m_notificationSound);
        cfg.setValue("soundVolume", m_soundVolume);
        cfg.setValue("hideOnMaximized", m_hideOnMaximized);
        cfg.setValue("hideOnFullscreen", m_hideOnFullscreen);
        cfg.setValue("soundFilePath", m_soundFilePath);
        cfg.setValue("componentOrder", m_componentOrder.join(","));
        QStringList visPairs;
        for (auto it = m_componentVisibility.begin(); it != m_componentVisibility.end(); ++it)
            visPairs << QString("%1:%2").arg(it.key()).arg(it.value().toBool() ? 1 : 0);
        cfg.setValue("componentVisibility", visPairs.join(","));
        cfg.sync();
    }

    void checkNotifications() {
        if (!m_loaded) return;
        QVariantList todayClasses = getTodayClasses();
        QDateTime now = QDateTime::currentDateTime().addSecs(m_timeOffset * 60);
        int nowSec = now.time().hour() * 3600 + now.time().minute() * 60 + now.time().second();
        int currentIdx = -1;
        for (int i = 0; i < todayClasses.size(); i++) {
            QVariantMap cls = todayClasses[i].toMap();
            int startSec = timeToSeconds(cls["start_time"].toString());
            int endSec = timeToSeconds(cls["end_time"].toString());
            int normStart = ((startSec % 86400) + 86400) % 86400;
            int normEnd = ((endSec % 86400) + 86400) % 86400;
            bool inClass = false;
            if (normStart <= normEnd) {
                inClass = (nowSec >= normStart && nowSec < normEnd);
            } else {
                inClass = (nowSec >= normStart || nowSec < normEnd);
            }
            if (inClass) {
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
                int startSec = timeToSeconds(cls["start_time"].toString());
                int normStart = ((startSec % 86400) + 86400) % 86400;
                int prepSec = normStart - m_preparationTime * 60;
                if (prepSec < 0) prepSec += 86400;
                if (nowSec == prepSec && i != m_lastPrepNotifiedIndex) {
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
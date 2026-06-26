#include "pluginmanager.h"
#include "classboardplugin.h"

#include <QPluginLoader>
#include <QDir>
#include <QCoreApplication>
#include <QFileInfo>

PluginManager::PluginManager(QObject *parent)
    : QObject(parent)
{
    registerBuiltinPlugins();
    loadExternalPlugins();
}

PluginManager::~PluginManager()
{
    clearPlugins();
}

void PluginManager::registerBuiltinPlugins()
{
    const QString qmlBase = "qrc:/qt/qml/ClassBoard/";

    PluginEntry timeEntry;
    timeEntry.id = "time";
    timeEntry.name = QStringLiteral("\u65e5\u671f");
    timeEntry.description = QStringLiteral("\u663e\u793a\u4eca\u5929\u7684\u65e5\u671f\u548c\u661f\u671f\u3002");
    timeEntry.icon = "icons/schedule.svg";
    timeEntry.version = QStringLiteral("1.0");
    timeEntry.author = QStringLiteral("NEO ClassBoard");
    timeEntry.componentUrl = QUrl(qmlBase + "TimeSection.qml");
    timeEntry.preferredWidth = 96;
    timeEntry.fillWidth = false;
    timeEntry.isBuiltin = true;
    m_entries.append(timeEntry);

    PluginEntry classListEntry;
    classListEntry.id = "classlist";
    classListEntry.name = QStringLiteral("\u8bfe\u7a0b\u8868");
    classListEntry.description = QStringLiteral("\u663e\u793a\u5f53\u524d\u7684\u8bfe\u7a0b\u8868\u4fe1\u606f\u3002");
    classListEntry.icon = "icons/dashboard.svg";
    classListEntry.version = QStringLiteral("1.0");
    classListEntry.author = QStringLiteral("NEO ClassBoard");
    classListEntry.componentUrl = QUrl(qmlBase + "ClassList.qml");
    classListEntry.preferredWidth = -1;
    classListEntry.fillWidth = true;
    classListEntry.isBuiltin = true;
    m_entries.append(classListEntry);

    PluginEntry nextClassEntry;
    nextClassEntry.id = "nextclass";
    nextClassEntry.name = QStringLiteral("\u4e0b\u4e00\u8282");
    nextClassEntry.description = QStringLiteral("\u663e\u793a\u4e0b\u4e00\u8282\u8bfe\u7684\u4fe1\u606f\u3002");
    nextClassEntry.icon = "icons/notifications.svg";
    nextClassEntry.version = QStringLiteral("1.0");
    nextClassEntry.author = QStringLiteral("NEO ClassBoard");
    nextClassEntry.componentUrl = QUrl(qmlBase + "NextClassWidget.qml");
    nextClassEntry.preferredWidth = 80;
    nextClassEntry.fillWidth = false;
    nextClassEntry.isBuiltin = true;
    m_entries.append(nextClassEntry);
}

void PluginManager::loadExternalPlugins()
{
    QDir dir(pluginsDirectory());
    if (!dir.exists()) {
        dir.mkpath(dir.absolutePath());
        return;
    }

    const QStringList filters = {
#ifdef Q_OS_WIN
        "*.dll"
#elif defined(Q_OS_MACOS)
        "*.dylib"
#else
        "*.so"
#endif
    };
    dir.setNameFilters(filters);

    const QFileInfoList files = dir.entryInfoList(QDir::Files | QDir::Readable);
    for (const QFileInfo &fileInfo : files) {
        const QString path = fileInfo.absoluteFilePath();
        QPluginLoader loader(path);
        QObject *instance = loader.instance();
        if (!instance) {
            qWarning() << "[PluginManager] Failed to load plugin" << path
                       << ":" << loader.errorString();
            continue;
        }

        ClassBoardPlugin *plugin = qobject_cast<ClassBoardPlugin *>(instance);
        if (!plugin) {
            qWarning() << "[PluginManager] Plugin does not implement ClassBoardPlugin:" << path;
            instance->deleteLater();
            continue;
        }

        if (hasPlugin(plugin->pluginId())) {
            qWarning() << "[PluginManager] Plugin id already registered:" << plugin->pluginId();
            continue;
        }

        plugin->initialize();

        PluginEntry entry;
        entry.id = plugin->pluginId();
        entry.name = plugin->pluginName();
        entry.description = plugin->pluginDescription();
        entry.icon = plugin->pluginIcon();
        entry.version = plugin->pluginVersion();
        entry.author = plugin->pluginAuthor();
        entry.componentUrl = plugin->componentUrl();
        entry.preferredWidth = plugin->preferredWidth();
        entry.fillWidth = plugin->fillWidth();
        entry.isBuiltin = false;
        entry.plugin = plugin;
        m_entries.append(entry);

        qDebug() << "[PluginManager] Loaded plugin:" << entry.id << entry.name;
    }
}

void PluginManager::clearPlugins()
{
    for (const PluginEntry &entry : std::as_const(m_entries)) {
        if (entry.plugin) {
            entry.plugin->shutdown();
            entry.plugin->deleteLater();
        }
    }
    m_entries.clear();
}

QVariantList PluginManager::plugins() const
{
    QVariantList list;
    for (const PluginEntry &entry : std::as_const(m_entries))
        list.append(entryToMetadata(entry));
    return list;
}

QStringList PluginManager::pluginIds() const
{
    QStringList ids;
    for (const PluginEntry &entry : std::as_const(m_entries))
        ids.append(entry.id);
    return ids;
}

bool PluginManager::isBuiltin(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entry.isBuiltin;
    return false;
}

bool PluginManager::hasPlugin(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return true;
    return false;
}

QUrl PluginManager::componentUrl(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entry.componentUrl;
    return QUrl();
}

int PluginManager::preferredWidth(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entry.preferredWidth;
    return -1;
}

bool PluginManager::fillWidth(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entry.fillWidth;
    return false;
}

QVariantMap PluginManager::pluginMetadata(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entryToMetadata(entry);
    return {};
}

QString PluginManager::pluginName(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entry.name;
    return id;
}

QString PluginManager::pluginIcon(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entry.icon;
    return "icons/dashboard.svg";
}

QString PluginManager::pluginDescription(const QString &id) const
{
    for (const PluginEntry &entry : std::as_const(m_entries))
        if (entry.id == id)
            return entry.description;
    return {};
}

void PluginManager::reloadPlugins()
{
    QList<PluginEntry> builtins;
    for (const PluginEntry &entry : std::as_const(m_entries)) {
        if (entry.isBuiltin)
            builtins.append(entry);
        else if (entry.plugin) {
            entry.plugin->shutdown();
            entry.plugin->deleteLater();
        }
    }
    m_entries = builtins;
    loadExternalPlugins();
    emit pluginsChanged();
}

QString PluginManager::pluginsDirectory() const
{
    return QCoreApplication::applicationDirPath() + "/plugins";
}

QVariantMap PluginManager::entryToMetadata(const PluginEntry &entry) const
{
    QVariantMap m;
    m.insert("id", entry.id);
    m.insert("name", entry.name);
    m.insert("description", entry.description);
    m.insert("icon", entry.icon);
    m.insert("version", entry.version);
    m.insert("author", entry.author);
    m.insert("componentUrl", entry.componentUrl.toString());
    m.insert("preferredWidth", entry.preferredWidth);
    m.insert("fillWidth", entry.fillWidth);
    m.insert("isBuiltin", entry.isBuiltin);
    return m;
}
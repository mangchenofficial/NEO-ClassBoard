#ifndef PLUGINMANAGER_H
#define PLUGINMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QUrl>
#include <QList>

class ClassBoardPlugin;

class PluginManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList plugins READ plugins NOTIFY pluginsChanged)
    Q_PROPERTY(QStringList pluginIds READ pluginIds NOTIFY pluginsChanged)

public:
    explicit PluginManager(QObject *parent = nullptr);
    ~PluginManager() override;

    QVariantList plugins() const;
    QStringList pluginIds() const;

    Q_INVOKABLE bool isBuiltin(const QString &id) const;
    Q_INVOKABLE bool hasPlugin(const QString &id) const;
    Q_INVOKABLE QUrl componentUrl(const QString &id) const;
    Q_INVOKABLE int preferredWidth(const QString &id) const;
    Q_INVOKABLE bool fillWidth(const QString &id) const;
    Q_INVOKABLE QVariantMap pluginMetadata(const QString &id) const;
    Q_INVOKABLE QString pluginName(const QString &id) const;
    Q_INVOKABLE QString pluginIcon(const QString &id) const;
    Q_INVOKABLE QString pluginDescription(const QString &id) const;

    Q_INVOKABLE void reloadPlugins();
    Q_INVOKABLE QString pluginsDirectory() const;

signals:
    void pluginsChanged();

private:
    struct PluginEntry {
        QString id;
        QString name;
        QString description;
        QString icon;
        QString version;
        QString author;
        QUrl componentUrl;
        int preferredWidth = -1;
        bool fillWidth = false;
        bool isBuiltin = false;
        ClassBoardPlugin *plugin = nullptr;
    };

    void registerBuiltinPlugins();
    void loadExternalPlugins();
    void clearPlugins();
    QVariantMap entryToMetadata(const PluginEntry &entry) const;

    QList<PluginEntry> m_entries;
};

#endif // PLUGINMANAGER_H
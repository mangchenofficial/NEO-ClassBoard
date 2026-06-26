#ifndef CLASSBOARDPLUGIN_H
#define CLASSBOARDPLUGIN_H

#include <QObject>
#include <QString>
#include <QUrl>
#include <QVariantMap>

class ClassBoardPlugin
{
public:
    virtual ~ClassBoardPlugin() = default;

    virtual QString pluginId() const = 0;
    virtual QString pluginName() const = 0;
    virtual QString pluginDescription() const = 0;
    virtual QString pluginIcon() const = 0;
    virtual QString pluginVersion() const = 0;
    virtual QString pluginAuthor() const = 0;

    virtual QUrl componentUrl() const = 0;
    virtual int preferredWidth() const = 0;
    virtual bool fillWidth() const = 0;

    virtual void initialize() {}
    virtual void shutdown() {}

    virtual QVariantMap metadata() const
    {
        QVariantMap m;
        m.insert("id", pluginId());
        m.insert("name", pluginName());
        m.insert("description", pluginDescription());
        m.insert("icon", pluginIcon());
        m.insert("version", pluginVersion());
        m.insert("author", pluginAuthor());
        m.insert("componentUrl", componentUrl().toString());
        m.insert("preferredWidth", preferredWidth());
        m.insert("fillWidth", fillWidth());
        return m;
    }
};

#define ClassBoardPlugin_iid "org.neoclassboard.ClassBoardPlugin/1.0"

Q_DECLARE_INTERFACE(ClassBoardPlugin, ClassBoardPlugin_iid)

#endif // CLASSBOARDPLUGIN_H
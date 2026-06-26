#ifndef SAMPLEPLUGIN_H
#define SAMPLEPLUGIN_H

#include <QObject>
#include "../../classboardplugin.h"

class SamplePlugin : public QObject, public ClassBoardPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID ClassBoardPlugin_iid FILE "sampleplugin.json")
    Q_INTERFACES(ClassBoardPlugin)

public:
    explicit SamplePlugin(QObject *parent = nullptr);

    QString pluginId() const override;
    QString pluginName() const override;
    QString pluginDescription() const override;
    QString pluginIcon() const override;
    QString pluginVersion() const override;
    QString pluginAuthor() const override;

    QUrl componentUrl() const override;
    int preferredWidth() const override;
    bool fillWidth() const override;

    void initialize() override;
};

#endif // SAMPLEPLUGIN_H
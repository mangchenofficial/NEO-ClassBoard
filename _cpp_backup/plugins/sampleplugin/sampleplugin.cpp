#include "sampleplugin.h"

#include <QResource>
#include <QDebug>

SamplePlugin::SamplePlugin(QObject *parent)
    : QObject(parent)
{
}

QString SamplePlugin::pluginId() const
{
    return QStringLiteral("weather");
}

QString SamplePlugin::pluginName() const
{
    return QStringLiteral("\u5929\u6c14");
}

QString SamplePlugin::pluginDescription() const
{
    return QStringLiteral("\u663e\u793a\u5f53\u524d\u5929\u6c14\u4fe1\u606f\uff08\u793a\u4f8b\u63d2\u4ef6\uff09\u3002");
}

QString SamplePlugin::pluginIcon() const
{
    return "icons/wb_sunny.svg";
}

QString SamplePlugin::pluginVersion() const
{
    return QStringLiteral("1.0");
}

QString SamplePlugin::pluginAuthor() const
{
    return QStringLiteral("NEO ClassBoard Sample");
}

QUrl SamplePlugin::componentUrl() const
{
    return QUrl(QStringLiteral("qrc:/sampleplugin/WeatherWidget.qml"));
}

int SamplePlugin::preferredWidth() const
{
    return 80;
}

bool SamplePlugin::fillWidth() const
{
    return false;
}

void SamplePlugin::initialize()
{
    Q_INIT_RESOURCE(sampleplugin);
    qDebug() << "[SamplePlugin] initialized:" << pluginId();
}
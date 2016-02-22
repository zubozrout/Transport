#include <QtQml>
#include <QtQml/QQmlContext>
#include "backend.h"
#include "api.h"


void BackendPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("Transport"));

    qmlRegisterType<Api>(uri, 1, 0, "Api");
}

void BackendPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}


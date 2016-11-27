#include <QtQml>
#include <QtQml/QQmlContext>
#include "backend.h"
#include "mytype.h"

#include <QtSql/qsqldatabase.h>
#include <qcoreapplication.h>


void BackendPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("Transport"));

    qmlRegisterType<MyType>(uri, 1, 0, "MyType");

    QTextStream(stdout) << "app name:" << endl;
    QTextStream(stdout) << QCoreApplication::applicationName() << endl;

   //QTextStream(stdout) << QQmlEngine::offlineStoragePath() << endl;
}

void BackendPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}

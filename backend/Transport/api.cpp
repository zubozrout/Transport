#include "api.h"

Api::Api(QObject *parent) : QObject(parent), api_request(""), api_response(""), api_running(false) {
}

Api::~Api() {
}

void Api::httpRequest(QString url) {
    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    connect(manager, SIGNAL(finished(QNetworkReply*)), this, SLOT(replyFinished(QNetworkReply*)));
    reply = manager->get(QNetworkRequest(QUrl(url)));
    //QTextStream(stdout) << url << endl;
}

void Api::replyFinished(QNetworkReply* reply) {
    QByteArray bytes = reply->readAll();
    //int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    setResponse(QString::fromUtf8(bytes.data(), bytes.size()));
}

void Api::abort() {
    if(reply != NULL && reply->isOpen()) {
        reply->abort();
    }
}

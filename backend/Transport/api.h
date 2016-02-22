#ifndef API_H
#define API_H

#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>

#include <QObject>

class Api : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString request READ request WRITE setRequest NOTIFY requestChanged )
    Q_PROPERTY(QString response READ response NOTIFY responseChanged )
    Q_PROPERTY(bool running READ running NOTIFY runningChanged )

public:
    explicit Api(QObject *parent = 0);
    ~Api();
    void httpRequest(QString url);
    void abort();

public slots:
    void replyFinished(QNetworkReply *reply);

Q_SIGNALS:
    void requestChanged();
    void responseChanged();
    void runningChanged();

protected:
    QString request() {
        return api_request;
    }
    QString response() {
        return api_response;
    }
    bool running() {
        return api_running;
    }

    void setRequest(QString req) {
        api_request = req;
        if(req == "" || req == NULL) {
            abort();
            api_running = false;
        }
        else {
            httpRequest(req);
            api_running = true;
        }
        Q_EMIT requestChanged();
        Q_EMIT runningChanged();
    }

    void setResponse(QString resp) {
        api_running = false;
        api_response = resp;
        Q_EMIT runningChanged();
        Q_EMIT responseChanged();
    }

    QString api_request;
    QString api_response;
    bool api_running;

    QNetworkReply* reply;
};

#endif // API_H


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
    Q_PROPERTY(int statusCode READ statusCode NOTIFY statusCodeChanged )
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
    void statusCodeChanged();
    void runningChanged();

protected:
    QString request() {
        return api_request;
    }
    QString response() {
        return api_response;
    }
    int statusCode() {
        return api_statusCode;
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

    void setResponse(QString response, int statusCode) {
        api_running = false;
        api_response = response;
        api_statusCode = statusCode;
        Q_EMIT runningChanged();
        Q_EMIT responseChanged();
        Q_EMIT statusCodeChanged();
    }

    QString api_request;
    QString api_response;
    int api_statusCode;
    bool api_running;

    QNetworkReply* reply;
};

#endif // API_H


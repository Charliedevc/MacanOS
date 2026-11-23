// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QTcpSocket>
#include <QTimer>
#include <QElapsedTimer>
#include <QVariantMap>
#include <QSettings>
#include <QQuickWindow>
class DisplayClient : public QObject {
 Q_OBJECT
 Q_PROPERTY(QVariantMap state READ state NOTIFY changed)
 Q_PROPERTY(QString role READ role CONSTANT)
 Q_PROPERTY(QString mode READ mode NOTIFY changed)
 Q_PROPERTY(QString localApp READ localApp NOTIFY changed)
 Q_PROPERTY(QString selectedApp READ selectedApp NOTIFY changed)
 Q_PROPERTY(bool online READ online NOTIFY changed)
 Q_PROPERTY(bool available READ available NOTIFY changed)
 Q_PROPERTY(double serverTime READ serverTime NOTIFY tick)
 Q_PROPERTY(QString message READ message NOTIFY changed)
public:
 DisplayClient(QString role,int port,QVariantMap spec,QString storage,QString diagnostic,QString control,QString presence,QObject *parent=nullptr);
 ~DisplayClient() override;
 void attachWindow(QQuickWindow *w);
 QVariantMap state()const{return shared;}
 QString role()const{return roleName;}
 QString mode()const{return online()?shared.value("effectiveMode","INDEPENDENT").toString():"INDEPENDENT";}
 QString localApp()const{return local;}
 QString selectedApp()const{return mode()=="INDEPENDENT"?local:shared.value(mode()=="UNIFIED"?"unifiedScene":"sharedApp","navigation").toString();}
 bool online()const{return registered&&socket.state()==QAbstractSocket::ConnectedState&&elapsed.elapsed()-lastState<1200;}
 bool available()const{return present&&outputPresent;}
 double serverTime()const{return elapsed.elapsed()+offset;}
 QString message()const{return lastError;}
 void setOutputPresent(bool value);
 Q_INVOKABLE void command(QString op,QVariantMap args={});
 Q_INVOKABLE void selectApp(QString app);
 Q_INVOKABLE void modeSelect(QString m){command("setMode",{{"mode",m}});}
 Q_INVOKABLE void touch(double x,double y);
signals:
 void changed();void tick();
private:
 void send(QString op,QVariantMap args={});
 void read();void poll();void saveDiagnostic();void reconnect();
 QTcpSocket socket;QElapsedTimer elapsed;QTimer fast,maintenance,retry,resizeTimer;
 QString roleName,local,lastError,diagnostic,control,presence;int port,retryMs=100,nextId=0;
 QVariantMap spec,shared;QSettings settings;QByteArray buffer;
 bool registered=false,present=true,outputPresent=true;double offset=0,uncertainty=0; qint64 lastState=-10000,lastPing=-10000;int registerId=0;QHash<int,qint64> pings;
 QHash<int,QString> operations,controlRequests;QVariantMap controlResult;
 QString lastControl;QQuickWindow *window=nullptr;
};

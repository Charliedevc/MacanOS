// SPDX-License-Identifier: GPL-3.0-or-later
#include "displaycoordinator.h"
#include "fixturemodel.h"
#include <QCoreApplication>
#include <QCommandLineParser>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTimer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>
#include <QTextStream>
struct Peer {QString owner,role; QByteArray buffer;};
int main(int argc,char **argv){
 QCoreApplication app(argc,argv);QCoreApplication::setApplicationName("macanos-display-server");
 QCommandLineParser p;p.addHelpOption();p.addOptions({{{"p","port"},"Loopback TCP port (0 for ephemeral)","port","45670"},{{"s","settings"},"Mode settings file","file","mode-settings.json"}});p.process(app);
 bool valid=false;uint port=p.value("port").toUInt(&valid);if(!valid||port>65535)return 2;
 DisplayCoordinator coordinator(p.value("settings"));FixtureModel fixture;QTcpServer server;QHash<QTcpSocket*,Peer> peers;
 auto snapshot=[&](){auto s=coordinator.state();s["model"]=fixture.state(coordinator.now());s["serverPid"]=QCoreApplication::applicationPid();return s;};
 auto send=[](QTcpSocket *s,const QVariantMap &m){if(s->bytesToWrite()>262144){s->abort();return;}s->write(QJsonDocument::fromVariant(m).toJson(QJsonDocument::Compact)+'\n');};
 auto broadcast=[&](){const auto s=snapshot();for(auto sock:peers.keys())send(sock,{{"event","state"},{"value",s}});};
 QObject::connect(&coordinator,&DisplayCoordinator::stateChanged,&app,broadcast);
 QObject::connect(&server,&QTcpServer::newConnection,&app,[&]{while(server.hasPendingConnections()){
  auto *socket=server.nextPendingConnection();peers.insert(socket,{QUuid::createUuid().toString(),{}, {}});send(socket,{{"event","state"},{"value",snapshot()}});
  QObject::connect(socket,&QTcpSocket::disconnected,&app,[&,socket]{const auto peer=peers.take(socket);coordinator.unregisterDisplay(peer.role,peer.owner);socket->deleteLater();});
  QObject::connect(socket,&QTcpSocket::readyRead,&app,[&,socket]{
   if(!peers.contains(socket))return;
   auto &peer=peers[socket];peer.buffer+=socket->readAll();if(peer.buffer.size()>65536){socket->abort();return;}
   while(peer.buffer.contains('\n')){
    const int n=peer.buffer.indexOf('\n');QByteArray line=peer.buffer.left(n);peer.buffer.remove(0,n+1);
    QJsonParseError parse;const auto doc=QJsonDocument::fromJson(line,&parse);const auto req=doc.object();const QString op=req["op"].toString();const auto a=req["args"].toObject().toVariantMap();
    bool ok=false;QVariant result;QString error;
    if(parse.error!=QJsonParseError::NoError||!doc.isObject())error="Malformed JSON object";
    else if(op=="ping"){ok=true;result=coordinator.now();}
    else if(op=="getState"){ok=true;result=snapshot();}
    else if(op=="register"){
     const auto role=a.value("role").toString();if(!peer.role.isEmpty()&&peer.role!=role)error="One role per connection";
     else {ok=coordinator.registerDisplay(role,peer.owner,a.value("display").toMap());if(ok)peer.role=role;else error=coordinator.lastError();}
    }
    else if(peer.role.isEmpty())error="Register a display first";
    else if(op=="heartbeat"){ok=coordinator.heartbeat(peer.role,peer.owner,a.value("available",true).toBool());error=coordinator.lastError();}
    else if(!coordinator.owns(peer.role,peer.owner))error="Display ownership or availability lost; register again";
    else if(op=="setMode"){ok=coordinator.setMode(a.value("mode").toString());error=coordinator.lastError();}
    else if(op=="setSharedApp"){ok=coordinator.setSharedApp(a.value("app").toString());error=coordinator.lastError();}
    else if(op=="setUnifiedScene"){ok=coordinator.setUnifiedScene(a.value("scene").toString());error=coordinator.lastError();}
    else if(op=="setBezelGap"){bool number=false;double gap=a.value("gapDip").toDouble(&number);if(number)ok=coordinator.setBezelGap(gap);error=number?coordinator.lastError():"Gap must be numeric";}
    else if(op=="touch"){result=coordinator.mapTouch(peer.role,peer.owner,a.value("x",-1).toDouble(),a.value("y",-1).toDouble(),a.value("generation",-1).toInt());ok=result.toMap().value("valid").toBool();error="Touch rejected";}
    else if(op=="model"){ok=fixture.command(peer.role,a.value("method").toString(),a,coordinator.now());error=fixture.error;if(ok)broadcast();}
    else error="Operation prohibited or unsupported; no vehicle commands are exposed";
    send(socket,{{"id",req["id"].toVariant()},{"ok",ok},{"result",result},{"error",ok?QString():error}});
   }
  });
 }});
 QTimer timer;QObject::connect(&timer,&QTimer::timeout,&app,[&]{coordinator.expire();broadcast();});timer.start(200);
 if(!server.listen(QHostAddress::LocalHost,quint16(port))){qCritical("Cannot listen: %s",qPrintable(server.errorString()));return 3;}
 QTextStream(stdout)<<QJsonDocument(QJsonObject{{"listeningPort",server.serverPort()},{"sessionId",coordinator.session()},{"pid",QCoreApplication::applicationPid()}}).toJson(QJsonDocument::Compact)<<Qt::endl;
 return app.exec();
}

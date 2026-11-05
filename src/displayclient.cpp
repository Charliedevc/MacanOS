// SPDX-License-Identifier: GPL-3.0-or-later
#include "displayclient.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QSaveFile>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <cmath>
DisplayClient::DisplayClient(QString role,int p,QVariantMap display,QString storage,QString diag,QString ctl,QString pres,QObject *parent):QObject(parent),roleName(role),diagnostic(diag),control(ctl),presence(pres),port(p),spec(display),settings(storage,QSettings::IniFormat){
 elapsed.start();local=settings.value("app",role=="driver"?"navigation":"media").toString();if(local!="navigation"&&local!="media")local="navigation";
 retry.setSingleShot(true);connect(&retry,&QTimer::timeout,this,&DisplayClient::reconnect);
 connect(&socket,&QTcpSocket::connected,this,[this]{buffer.clear();registerId=nextId+1;send("register",{{"role",roleName},{"display",spec}});retryMs=100;});
 connect(&socket,&QTcpSocket::readyRead,this,&DisplayClient::read);
 connect(&socket,&QTcpSocket::disconnected,this,[this]{registered=false;lastError="Backend offline — local layout retained";pings.clear();operations.clear();controlRequests.clear();retry.start(retryMs);retryMs=qMin(3000,retryMs*2);emit changed();});
 connect(&socket,&QTcpSocket::errorOccurred,this,[this]{registered=false;if(!retry.isActive())retry.start(retryMs);retryMs=qMin(3000,retryMs*2);emit changed();});
 connect(&fast,&QTimer::timeout,this,[this]{emit tick();});fast.start(16);
 connect(&maintenance,&QTimer::timeout,this,&DisplayClient::poll);maintenance.start(250);reconnect();
}
void DisplayClient::attachWindow(QQuickWindow *w){
 window=w;resizeTimer.setSingleShot(true);resizeTimer.setInterval(150);
 connect(w,&QQuickWindow::widthChanged,this,[this]{resizeTimer.start();});
 connect(w,&QQuickWindow::heightChanged,this,[this]{resizeTimer.start();});
 connect(&resizeTimer,&QTimer::timeout,this,[this]{
  spec["widthPx"]=window->width()*spec.value("scale").toDouble();spec["heightPx"]=window->height()*spec.value("scale").toDouble();
  if(registered){registerId=nextId+1;send("register",{{"role",roleName},{"display",spec}});}
 });
}
void DisplayClient::reconnect(){if(socket.state()==QAbstractSocket::UnconnectedState)socket.connectToHost(QHostAddress::LocalHost,quint16(port));}
void DisplayClient::send(QString op,QVariantMap args){if(socket.state()!=QAbstractSocket::ConnectedState)return;const int id=++nextId;operations[id]=op;
 if(op=="ping")pings[id]=elapsed.elapsed();
 socket.write(QJsonDocument::fromVariant(QVariantMap{{"id",id},{"op",op},{"args",args}}).toJson(QJsonDocument::Compact)+'\n');
}
void DisplayClient::read(){buffer+=socket.readAll();if(buffer.size()>262144){socket.abort();return;}
 while(buffer.contains('\n')){int n=buffer.indexOf('\n');const auto j=QJsonDocument::fromJson(buffer.left(n)).object();buffer.remove(0,n+1);
  if(j["event"]=="state"){
   const auto incoming=j["value"].toObject().toVariantMap();const bool newSession=shared.value("sessionId")!=incoming.value("sessionId");
   shared=incoming;lastState=elapsed.elapsed();if(newSession){offset=shared.value("serverMs").toDouble()-elapsed.elapsed();uncertainty=1000;lastPing=-10000;pings.clear();}emit changed();
  } else {
   int id=j["id"].toInt();const auto operation=operations.take(id);if(controlRequests.contains(id)){controlResult=j.toVariantMap();controlResult["sequence"]=controlRequests.take(id);}
   if(id==registerId){registered=j["ok"].toBool();if(!registered)socket.disconnectFromHost();}
   if(pings.contains(id)){const auto sent=pings.take(id);const double rtt=elapsed.elapsed()-sent;if(j["ok"].toBool()){offset=j["result"].toDouble()-(sent+elapsed.elapsed())/2.;uncertainty=rtt/2.;}}
   if(!j["ok"].toBool())lastError=j["error"].toString();else if(id!=registerId&&operation!="heartbeat"&&operation!="ping")lastError.clear();emit changed();
  }
 }
}
void DisplayClient::command(QString op,QVariantMap args){if(!online()){lastError="Backend offline: action unavailable";emit changed();return;}send(op,args);}
void DisplayClient::selectApp(QString app){if(app!="media"&&app!="navigation")return;
 if(mode()=="INDEPENDENT"){local=app;settings.setValue("app",local);settings.sync();emit changed();}
 else command(mode()=="UNIFIED"?"setUnifiedScene":"setSharedApp",{{mode()=="UNIFIED"?"scene":"app",app}});
}
void DisplayClient::touch(double x,double y){const auto t=shared.value("transition").toMap();command("touch",{{"x",x*spec.value("scale").toDouble()},{"y",y*spec.value("scale").toDouble()},{"generation",t.value("generation")}});}
void DisplayClient::setOutputPresent(bool value){outputPresent=value;if(registered)send("heartbeat",{{"available",available()}});if(window)window->setVisible(available());emit changed();}
void DisplayClient::poll(){
 bool visible=true;if(!presence.isEmpty()){QFile f(presence);if(f.open(QIODevice::ReadOnly))visible=QJsonDocument::fromJson(f.readAll()).object().value(roleName).toBool(true);}
 if(present!=visible){present=visible;if(window)window->setVisible(available());emit changed();}
 if(registered)send("heartbeat",{{"available",available()}});
 if(online()&&elapsed.elapsed()-lastPing>1000){lastPing=elapsed.elapsed();send("ping");}
 // A connected but silent backend must not leave a frozen coordinated canvas.
 if(registered&&elapsed.elapsed()-lastState>1200){lastError="Backend stale — local fallback";emit changed();if(elapsed.elapsed()-lastState>3000)socket.abort();}
 if(!control.isEmpty()){QFile f(control);if(f.open(QIODevice::ReadOnly)){
  const auto j=QJsonDocument::fromJson(f.readAll()).object();const QString seq=j["sequence"].toVariant().toString();
  if(!seq.isEmpty()&&seq!=lastControl){lastControl=seq;const int before=nextId;const auto op=j["op"].toString();const auto args=j["args"].toObject().toVariantMap();
   if(op=="localApp")selectApp(args.value("app").toString());
   else if(op=="screenshot"&&window){QString path=args.value("path").toString();QTimer::singleShot(100,this,[this,path]{QDir().mkpath(QFileInfo(path).absolutePath());bool ok=window&&window->grabWindow().save(path);controlResult={{"sequence",lastControl},{"ok",ok}};});}
   else if(op=="quit")QCoreApplication::quit();else command(op,args);
   if(nextId!=before)controlRequests[nextId]=seq;else if(op!="screenshot")controlResult={{"sequence",seq},{"ok",op=="localApp"}};
  }
 }}saveDiagnostic();
}
void DisplayClient::saveDiagnostic(){if(diagnostic.isEmpty())return;
 QVariantMap d{{"role",roleName},{"mode",mode()},{"localApp",local},{"selectedApp",selectedApp()},{"online",online()},{"available",available()},
 {"pid",QCoreApplication::applicationPid()},{"serverTime",serverTime()},{"clockUncertaintyMs",uncertainty},{"state",shared},{"message",lastError},{"controlSequence",lastControl},{"controlResult",controlResult}};
 if(window){d["windowWidth"]=window->width();d["windowHeight"]=window->height();}
 QSaveFile f(diagnostic);if(f.open(QIODevice::WriteOnly)){f.write(QJsonDocument::fromVariant(d).toJson());f.commit();}
}

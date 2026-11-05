// SPDX-License-Identifier: GPL-3.0-or-later
#include "displaycoordinator.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QSaveFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>
#include <cmath>
#include <algorithm>
static bool modeValid(const QString &s){return s=="INDEPENDENT"||s=="UNIFIED"||s=="SHARED";}
static bool appValid(const QString &s){return s=="navigation"||s=="media";}
DisplayCoordinator::DisplayCoordinator(QString settingsFile,Clock supplied,QObject *parent):QObject(parent),file(std::move(settingsFile)) {
 elapsed.start();clock=supplied?std::move(supplied):Clock([this]{return elapsed.elapsed();});sessionId=QUuid::createUuid().toString(QUuid::WithoutBraces);
 transition={{"generation",0},{"fromMode",effective},{"toMode",effective},{"fromApp",focus},{"toApp",focus},
   {"fromScene",scene},{"toScene",scene},{"startMs",0},{"durationMs",0}};
 QFile f(file);if(f.open(QIODevice::ReadOnly)){
  if(f.size()>65536){error="Settings exceed limit; using independent defaults";return;}
  const auto j=QJsonDocument::fromJson(f.readAll()).object();
  if(j["schema"].toInt()!=1||!modeValid(j["mode"].toString())){error="Invalid settings; using independent defaults";return;}
  requested=j["mode"].toString();if(appValid(j["sharedApp"].toString()))focus=j["sharedApp"].toString();
  if(appValid(j["unifiedScene"].toString()))scene=j["unifiedScene"].toString();
  const double g=j["bezelGapDip"].toDouble(24);if(std::isfinite(g)&&g>=0&&g<=400)gap=g;
 }

}
bool DisplayCoordinator::validSpec(const QVariantMap &s) const {
 const double w=s.value("widthPx").toDouble(),h=s.value("heightPx").toDouble(),d=s.value("scale").toDouble();
 if(!std::isfinite(w)||!std::isfinite(h)||!std::isfinite(d)||w<320||w>7680||h<240||h>4320||d<.5||d>4)return false;
 if(s.value("outputId").toString().isEmpty()||s.value("outputId").toString().size()>120)return false;
 const auto a=s.value("touchMatrix",QVariantList{1,0,0,0,1,0}).toList();if(a.size()!=6)return false;
 for(const auto &v:a)if(!std::isfinite(v.toDouble())||std::abs(v.toDouble())>4)return false;
 return std::abs(a[0].toDouble()*a[4].toDouble()-a[1].toDouble()*a[3].toDouble())>1e-6;
}
bool DisplayCoordinator::registerDisplay(const QString &role,const QString &owner,const QVariantMap &spec){
 if((role!="driver"&&role!="passenger")||owner.isEmpty()||!validSpec(spec))return reject("Invalid role or display geometry");
 if(displays.contains(role)&&displays[role].owner!=owner&&usable(role))return reject("Role already owned by another healthy process");
 if(displays.contains(role)&&displays[role].spec!=spec&&effective!="INDEPENDENT")resumeRequired=true;
 displays[role]={owner,spec,now(),true};error.clear();recompute();return true;
}
bool DisplayCoordinator::heartbeat(const QString &role,const QString &owner,bool available){
 if(!displays.contains(role)||displays[role].owner!=owner)return reject("Display must register again");
 auto &d=displays[role];const bool changed=usable(role)!=available;d.available=available;d.lastSeen=now();
 if(changed)recompute(!available);return true;
}
void DisplayCoordinator::unregisterDisplay(const QString &role,const QString &owner){
 if(displays.contains(role)&&displays[role].owner==owner){displays.remove(role);recompute(true);}
}
bool DisplayCoordinator::usable(const QString &r) const {return displays.contains(r)&&displays[r].available&&now()-displays[r].lastSeen<=HeartbeatExpiryMs;}
bool DisplayCoordinator::readyPair() const{return usable("driver")&&usable("passenger");}
void DisplayCoordinator::expire(){
 bool changed=false;for(auto i=displays.begin();i!=displays.end();++i)if(i->available&&now()-i->lastSeen>HeartbeatExpiryMs){i->available=false;changed=true;}
 if(changed)recompute(true);
}
QVariantMap DisplayCoordinator::geometry() const {
 QVariantMap viewports;double x=0,height=0;
 for(const QString role:{QString("driver"),QString("passenger")}){
  if(!displays.contains(role))continue;
  const auto &s=displays[role].spec;const double w=s.value("widthPx").toDouble()/s.value("scale").toDouble(),h=s.value("heightPx").toDouble()/s.value("scale").toDouble();
  viewports[role]=QVariantMap{{"x",x},{"y",0},{"width",w},{"height",h},{"scale",s.value("scale")}};
  x+=w+(role=="driver"?gap:0);height=std::max(height,h);
 }
 return {{"width",x},{"height",height},{"gapDip",gap},{"viewports",viewports},{"units","logical-DIP; top aligned"}};
}
bool DisplayCoordinator::busy() const{return transition.value("durationMs").toInt()>0&&now()<transition.value("startMs").toLongLong()+transition.value("durationMs").toLongLong();}
bool DisplayCoordinator::persist(const QString &m,const QString &f,const QString &s,double g){
 if(file.isEmpty())return true;
 if(!QDir().mkpath(QFileInfo(file).absolutePath()))return reject("Cannot create mode settings directory");
 QSaveFile out(file);const QByteArray bytes=QJsonDocument(QJsonObject{{"schema",1},{"mode",m},{"sharedApp",f},{"unifiedScene",s},{"bezelGapDip",g}}).toJson();
 if(!out.open(QIODevice::WriteOnly)||out.write(bytes)!=bytes.size()||!out.commit())return reject("Cannot persist display mode");return true;
}
void DisplayCoordinator::transitionTo(const QString &m,bool immediate){
 transition={{"generation",++generation},{"fromMode",effective},{"toMode",m},{"fromApp",focus},{"toApp",focus},{"fromScene",scene},{"toScene",scene},
 {"startMs",now()+(immediate?0:TransitionLeadMs)},{"durationMs",immediate?0:TransitionDurationMs}};effective=m;
}
void DisplayCoordinator::recompute(bool immediate){
 const auto g=geometry();QString target=requested;
 const bool distinct=!readyPair()||displays["driver"].spec.value("outputId")!=displays["passenger"].spec.value("outputId");
 const bool supported=g.value("width").toDouble()<=8192&&g.value("height").toDouble()<=2160&&distinct;
 if((!readyPair()||!distinct||(effective=="UNIFIED"&&!supported))&&effective!="INDEPENDENT")resumeRequired=true;
 if(!readyPair()||!distinct||resumeRequired||(requested=="UNIFIED"&&!supported))target="INDEPENDENT";
 if(target!=effective)transitionTo(target,immediate||target=="INDEPENDENT");
 ++revision;emit stateChanged();
}
bool DisplayCoordinator::setMode(const QString &m){
 if(!modeValid(m))return reject("Unknown display mode");
 if(m!="INDEPENDENT"&&!readyPair())return reject("Both healthy display processes are required");
 if(m!="INDEPENDENT"&&displays["driver"].spec.value("outputId")==displays["passenger"].spec.value("outputId"))return reject("Coordinated modes require distinct output identities");
 const auto g=geometry();if(m=="UNIFIED"&&(g.value("width").toDouble()>8192||g.value("height").toDouble()>2160))return reject("Unified canvas exceeds renderer limit");
 if(busy()&&m!=effective&&m!="INDEPENDENT")return reject("A coordinated transition is in progress");
 if(!persist(m,focus,scene,gap))return false;
 requested=m;resumeRequired=false;error.clear();if(m!=effective)transitionTo(m,m=="INDEPENDENT");++revision;emit stateChanged();return true;
}
bool DisplayCoordinator::setSharedApp(const QString &app){
 if(!appValid(app)||busy())return reject("Unsupported app or transition busy");if(app==focus)return true;
 if(!persist(requested,app,scene,gap))return false;
 const QString old=focus;transitionTo(effective);transition["fromApp"]=old;focus=app;transition["toApp"]=app;++revision;emit stateChanged();return true;
}
bool DisplayCoordinator::setUnifiedScene(const QString &s){
 if(!appValid(s)||busy())return reject("Unsupported scene or transition busy");if(s==scene)return true;
 if(!persist(requested,focus,s,gap))return false;
 const QString old=scene;transitionTo(effective);transition["fromScene"]=old;scene=s;transition["toScene"]=s;++revision;emit stateChanged();return true;
}
bool DisplayCoordinator::setBezelGap(double g){
 if(!std::isfinite(g)||g<0||g>400||busy())return reject("Invalid bezel gap or transition busy");
 if(!persist(requested,focus,scene,g))return false;gap=g;if(effective=="UNIFIED")resumeRequired=true;recompute(true);return true;
}
QVariantMap DisplayCoordinator::mapTouch(const QString &role,const QString &owner,double x,double y,int gen) const {
 if(!displays.contains(role)||displays[role].owner!=owner||!usable(role)||!std::isfinite(x)||!std::isfinite(y)||busy()||gen!=generation)return {{"valid",false}};
 const auto &s=displays[role].spec;const double w=s.value("widthPx").toDouble(),h=s.value("heightPx").toDouble();
 if(x<0||y<0||x>=w||y>=h)return {{"valid",false}};
 const auto m=s.value("touchMatrix",QVariantList{1,0,0,0,1,0}).toList();const double u=(x+.5)/w,v=(y+.5)/h;
 const double a=m[0].toDouble()*u+m[1].toDouble()*v+m[2].toDouble(),b=m[3].toDouble()*u+m[4].toDouble()*v+m[5].toDouble();
 if(a<0||b<0||a>=1||b>=1)return {{"valid",false}};
 const auto viewport=geometry()["viewports"].toMap()[role].toMap();
 return {{"valid",true},{"role",role},{"canvasX",std::clamp(a*viewport["width"].toDouble()-.5/s.value("scale").toDouble(),0.,viewport["width"].toDouble())+(effective=="UNIFIED"?viewport["x"].toDouble():0)},
 {"canvasY",std::clamp(b*viewport["height"].toDouble()-.5/s.value("scale").toDouble(),0.,viewport["height"].toDouble())},{"mode",effective},{"generation",generation}};
}
QVariantMap DisplayCoordinator::state() const {
 QVariantMap health;for(const auto &role:{QString("driver"),QString("passenger")})health[role]=QVariantMap{{"connected",displays.contains(role)},{"available",usable(role)}};
 return {{"schema",1},{"sessionId",sessionId},{"serverMs",now()},{"revision",revision},{"requestedMode",requested},{"effectiveMode",effective},
 {"sharedApp",focus},{"unifiedScene",scene},{"resumeRequired",resumeRequired},{"bothReady",readyPair()},{"geometry",geometry()},{"displays",health},
 {"transition",transition},{"error",error},{"animationEpochMs",0}};
}

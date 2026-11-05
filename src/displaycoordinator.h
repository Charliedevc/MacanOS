// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QObject>
#include <QVariantMap>
#include <QElapsedTimer>
#include <QHash>
#include <functional>

// Own one instance inside the backend. No vehicle, audio-device, or OBD ownership.
class DisplayCoordinator : public QObject {
 Q_OBJECT
 Q_CLASSINFO("octave.scope", "settings")
 Q_PROPERTY(QVariantMap state READ state NOTIFY stateChanged)
public:
 using Clock=std::function<qint64()>;
 explicit DisplayCoordinator(QString settingsFile,Clock clock={},QObject *parent=nullptr);
 QVariantMap state() const;
 qint64 now() const{return clock();}
 QString session() const{return sessionId;}
 bool registerDisplay(const QString &role,const QString &owner,const QVariantMap &spec);
 bool heartbeat(const QString &role,const QString &owner,bool available);
 void unregisterDisplay(const QString &role,const QString &owner);
 void expire();
 Q_INVOKABLE bool setMode(const QString &mode);
 Q_INVOKABLE bool setSharedApp(const QString &app);
 Q_INVOKABLE bool setUnifiedScene(const QString &scene);
 Q_INVOKABLE bool setBezelGap(double gapDip);
 QVariantMap mapTouch(const QString &role,const QString &owner,double nativeX,double nativeY,int generation) const;
 bool owns(const QString &role,const QString &owner) const {return displays.contains(role)&&displays[role].owner==owner&&usable(role);}
 QString lastError() const{return error;}
 static constexpr qint64 HeartbeatExpiryMs=1800,TransitionLeadMs=200,TransitionDurationMs=420;
signals:
 void stateChanged();
private:
 struct Display {QString owner;QVariantMap spec;qint64 lastSeen=0;bool available=true;};
 bool validSpec(const QVariantMap &spec) const;
 bool persist(const QString &mode,const QString &focus,const QString &scene,double gap);
 void recompute(bool immediate=false);
 void transitionTo(const QString &mode,bool immediate=false);
 bool busy() const;
 bool readyPair() const;
 bool usable(const QString &role) const;
 bool reject(const QString &reason){error=reason;return false;}
 QVariantMap geometry() const;
 QString file,requested="INDEPENDENT",effective="INDEPENDENT",focus="navigation",scene="navigation",error,sessionId;
 double gap=24;
 int revision=0,generation=0;
 bool resumeRequired=false;
 QHash<QString,Display> displays;
 QVariantMap transition;
 QElapsedTimer elapsed;
 Clock clock;
};

// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <QVariantMap>
#include <QString>
// Explicit simulation fixtures. Never opens an audio, GNSS or vehicle device.
class FixtureModel {
public:
 QVariantMap state(qint64 now) const;
 bool command(const QString &role,const QString &method,const QVariantMap &args,qint64 now);
 QString error;
private:
 bool playing=true;double position=38; qint64 anchor=0;int track=0,volume=36;
 QString destination="Coastal overlook",pending;bool approved=true;
 double playbackPosition(qint64 now) const;
};

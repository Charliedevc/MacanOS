// SPDX-License-Identifier: GPL-3.0-or-later
#include "fixturemodel.h"
#include <cmath>
static const QStringList tracks{"Night drive","Red horizon","After the rain"};
double FixtureModel::playbackPosition(qint64 now) const {return std::fmod(position+(playing?(now-anchor)/1000.:0),248.);}
QVariantMap FixtureModel::state(qint64 now) const {
 return {{"source","SIMULATOR FIXTURE — no live positioning or audio"},{"updatedMs",now},
 {"navigation",QVariantMap{{"destination",destination},{"pending",pending},{"approved",approved},{"distanceKm",18.4},{"etaMinutes",24},{"accuracyM",8},{"gpsStatus","SIMULATED"},
 {"route",QVariantList{QVariantMap{{"x",.06},{"y",.83}},QVariantMap{{"x",.24},{"y",.62}},QVariantMap{{"x",.43},{"y",.67}},QVariantMap{{"x",.59},{"y",.35}},QVariantMap{{"x",.80},{"y",.42}},QVariantMap{{"x",.95},{"y",.19}}}}}},
 {"media",QVariantMap{{"title",tracks[track]},{"artist","MacanOS studio fixtures"},{"playing",playing},{"position",playbackPosition(now)},{"duration",248},{"volume",volume},{"audible",false}}},
 {"vehicle",QVariantMap{{"speedMph",62+2*std::sin(now/8000.)},{"rpm",2180+80*std::sin(now/8000.)},{"status","SIMULATED · READ ONLY"}}}};
}
bool FixtureModel::command(const QString &role,const QString &method,const QVariantMap &args,qint64 now){
 error.clear();
 if(method=="togglePlayback"){position=playbackPosition(now);anchor=now;playing=!playing;return true;}
 if(method=="nextTrack"){track=(track+1)%tracks.size();position=0;anchor=now;return true;}
 if(method=="setVolume"){bool ok=false;const int v=args.value("volume").toInt(&ok);if(ok&&v>=0&&v<=100){volume=v;return true;}}
 if(method=="proposeDestination"&&role=="passenger"){
  const auto dest=args.value("destination").toString();if(QStringList{"Coastal overlook","City center","Mountain lodge"}.contains(dest)){pending=dest;return true;}
 }
 if(method=="approveDestination"&&role=="driver"&&!pending.isEmpty()){destination=pending;pending.clear();approved=true;return true;}
 if(method=="rejectDestination"&&role=="driver"){pending.clear();return true;}
 error="Unsupported fixture command, invalid argument or wrong display role";return false;
}

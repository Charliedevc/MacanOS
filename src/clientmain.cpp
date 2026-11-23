// SPDX-License-Identifier: GPL-3.0-or-later
#include "displayclient.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCommandLineParser>
#include <QScreen>
#include <QDir>
#include <cmath>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QPointer>
#include <QSaveFile>
#include <QTextStream>
#include <chrono>
#include <memory>
#include <mutex>
#include <vector>

namespace {
void recordFrames(QGuiApplication &app, QQuickWindow &window, const QString &role)
{
 const QString directory = qEnvironmentVariable("MACANOS_FRAME_LOG_DIR");
 if (directory.isEmpty())
  return;

 struct Samples {
  std::mutex mutex;
  std::vector<qint64> timestamps;
 };
 const auto samples = std::make_shared<Samples>();
 samples->timestamps.reserve(36000);
 QObject::connect(&window, &QQuickWindow::frameSwapped, &app, [samples] {
  const auto now = std::chrono::steady_clock::now().time_since_epoch();
  const auto nanoseconds = std::chrono::duration_cast<std::chrono::nanoseconds>(now).count();
  const std::lock_guard<std::mutex> lock(samples->mutex);
  if (samples->timestamps.size() < 36000)
   samples->timestamps.push_back(nanoseconds);
 }, Qt::DirectConnection);
 QObject::connect(&app, &QCoreApplication::aboutToQuit, &app, [samples, directory, role] {
  QSaveFile file(QDir(directory).filePath(role + "-frames.txt"));
  if (!file.open(QIODevice::WriteOnly)) {
   qWarning("Unable to open the frame timing log");
   return;
  }
  const std::lock_guard<std::mutex> lock(samples->mutex);
  QTextStream out(&file);
  for (const auto timestamp : samples->timestamps)
   out << timestamp << '\n';
  out.flush();
  if (!file.commit())
   qWarning("Unable to save the frame timing log");
 });
}
}

int main(int argc,char **argv){
 QGuiApplication app(argc,argv);app.setOrganizationName("MacanOS");app.setApplicationName("MacanOS v0.7.1 display simulator");
 QCommandLineParser p;p.addHelpOption();p.addOptions({
 {{"r","role"},"driver or passenger","role","driver"},{{"p","port"},"Loopback backend port","port","45670"},
 {"width","Configured native pixel width","pixels","1280"},{"height","Configured native pixel height","pixels","480"},{"scale","Native pixels per logical DIP","factor","1"},
 {"settings","Independent layout INI file","file"},{"diagnostic","Simulator diagnostic JSON file","file"},{"control","Simulator command JSON file","file"},{"presence","Simulated output-presence JSON file","file"},
 {"touch-profile","JSON file containing normalized affine touchMatrix[6]","file"},
 {"screen","Physical Qt screen index (omit for desktop window simulation)","index"},{"fullscreen","Full-screen window on selected output"}});p.process(app);
 const auto role=p.value("role");if(role!="driver"&&role!="passenger")return 2;
 bool ok=false;uint port=p.value("port").toUInt(&ok);if(!ok||port==0||port>65535)return 2;
 const double w=p.value("width").toDouble(),h=p.value("height").toDouble(),scale=p.value("scale").toDouble();
 if(!std::isfinite(w)||!std::isfinite(h)||!std::isfinite(scale)||w<320||w>7680||h<240||h>4320||scale<.5||scale>4)return 2;
 QScreen *target=nullptr;QString id="sim-"+role;
 if(p.isSet("screen")){const int index=p.value("screen").toInt(&ok);if(!ok||index<0||index>=app.screens().size())return 2;target=app.screens()[index];id=target->name();}
 const auto path=p.value("settings").isEmpty()?QDir::homePath()+"/.config/MacanOS/"+role+".ini":p.value("settings");
 QVariantMap displaySpec{{"widthPx",w},{"heightPx",h},{"scale",scale},{"outputId",id}};
 if(p.isSet("touch-profile")){QFile profile(p.value("touch-profile"));if(!profile.open(QIODevice::ReadOnly)||profile.size()>65536)return 2;
  const auto matrix=QJsonDocument::fromJson(profile.readAll()).object().value("touchMatrix").toArray();if(matrix.size()!=6)return 2;displaySpec["touchMatrix"]=matrix.toVariantList();}
 DisplayClient client(role,int(port),displaySpec,path,p.value("diagnostic"),p.value("control"),p.value("presence"));
 QQmlApplicationEngine engine;engine.rootContext()->setContextProperty("Display",&client);engine.rootContext()->setContextProperty("initialWidth",w/scale);engine.rootContext()->setContextProperty("initialHeight",h/scale);
 engine.rootContext()->setContextProperty("simulatorReducedMotion", qEnvironmentVariableIntValue("MACANOS_REDUCED_MOTION") == 1);
 engine.load(QUrl("qrc:/Main.qml"));if(engine.rootObjects().isEmpty())return 3;
 auto window=qobject_cast<QQuickWindow*>(engine.rootObjects().first());if(!window)return 4;
 recordFrames(app, *window, role);
 client.attachWindow(window);if(target){window->setScreen(target);window->setPosition(target->geometry().topLeft());
  auto current=std::make_shared<QPointer<QScreen>>(target);
  QObject::connect(&app,&QGuiApplication::screenRemoved,&app,[&client,current](QScreen *removed){if(removed==current->data()){*current=nullptr;client.setOutputPresent(false);}});
  QObject::connect(&app,&QGuiApplication::screenAdded,&app,[&client,window,id,current](QScreen *added){if(added->name()==id){*current=added;window->setScreen(added);client.setOutputPresent(true);}});
 }
 if(p.isSet("fullscreen"))window->showFullScreen();else window->show();return app.exec();
}

// SPDX-License-Identifier: GPL-3.0-or-later
#include <QtTest>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickItem>
#include <QTemporaryDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QDir>
#include "displayclient.h"
class LayoutTests:public QObject {
 Q_OBJECT
private slots:
 void responsive_data(){QTest::addColumn<QString>("role");QTest::addColumn<int>("w");QTest::addColumn<int>("h");for(auto role:{"driver","passenger"})for(auto size:{QSize(640,360),QSize(1024,360),QSize(1280,480),QSize(1920,720),QSize(1920,1080)})QTest::newRow(qPrintable(QString(role)+QString::number(size.width())+"x"+QString::number(size.height())))<<QString(role)<<size.width()<<size.height();}
 void responsive(){
  QFETCH(QString,role);QFETCH(int,w);QFETCH(int,h);QTemporaryDir dir;DisplayClient client(role,1,{{"widthPx",w},{"heightPx",h},{"scale",1},{"outputId","test"}},dir.filePath("app.ini"),"","","");
  QQmlApplicationEngine engine;QList<QQmlError> warnings;connect(&engine,&QQmlApplicationEngine::warnings,this,[&](const QList<QQmlError> &errors){warnings+=errors;});
  engine.rootContext()->setContextProperty("Display",&client);engine.rootContext()->setContextProperty("initialWidth",w);engine.rootContext()->setContextProperty("initialHeight",h);
  const bool reducedMotion = w == 640;
  engine.rootContext()->setContextProperty("simulatorReducedMotion", reducedMotion);
  engine.load(QUrl("qrc:/Main.qml"));QVERIFY(!engine.rootObjects().isEmpty());
  auto *window=qobject_cast<QQuickWindow*>(engine.rootObjects().first());QVERIFY(window);client.attachWindow(window);window->show();QTest::qWait(100);
  QCOMPARE(window->property("motionEnabled").toBool(), !reducedMotion);
  QCOMPARE(window->width(),w);QCOMPARE(window->height(),h);auto *panel=window->findChild<QQuickItem*>("primaryPanel");QVERIFY(panel);QVERIFY2(panel->width()>(w<800?280:350),qPrintable(QString("Collapsed primary panel: %1").arg(panel->width())));
  const QStringList controlNames{"action","mediaButton","navigationButton","displaySettingsButton","searchDestinationButton","resumeDisplayButton"};
  for(auto *item:window->findChildren<QQuickItem*>())if(controlNames.contains(item->objectName())&&item->isVisible()){
   QVERIFY2(item->height()>=48&&item->width()>=48,"Touch target below 48 DIP");
   const auto bounds=item->mapRectToScene(QRectF(0,0,item->width(),item->height()));
   QVERIFY2(bounds.left()>=0&&bounds.top()>=0&&bounds.right()<=w&&bounds.bottom()<=h,qPrintable(QString("Touch target outside viewport: %1,%2 %3x%4").arg(bounds.x()).arg(bounds.y()).arg(bounds.width()).arg(bounds.height())));
  }
  auto *button=window->findChild<QQuickItem*>(role=="driver"?"mediaButton":"navigationButton");QVERIFY(button);QPointF at=button->mapToScene(QPointF(button->width()/2,button->height()/2));QVERIFY(at.x()>0&&at.x()<w&&at.y()>0&&at.y()<h);
  QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,at.toPoint());QTRY_COMPARE(client.localApp(),role=="driver"?QString("media"):QString("navigation"));
  auto *displays=window->findChild<QQuickItem*>("displaySettingsButton");QVERIFY(displays);
  const auto displayPoint=displays->mapToScene(QPointF(displays->width()/2,displays->height()/2)).toPoint();
  QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,displayPoint);
  QTRY_VERIFY(window->property("settingsOpen").toBool());
  auto *settings=window->findChild<QQuickItem*>("displaySettings");QVERIFY(settings&&settings->isVisible());
  QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,displayPoint);
  QTRY_VERIFY(!settings->isVisible());
  for(const auto &warning:warnings)qWarning()<<warning;QVERIFY(warnings.isEmpty());
  auto shot=window->grabWindow();QVERIFY(!shot.isNull());QCOMPARE(shot.size(),QSize(w,h));
 }
 void destinationAndRecovery(){
  QTemporaryDir dir;
  QProcess server;
  server.start("./macanos-display-server", {"--port","0","--settings",dir.filePath("modes.json")});
  QVERIFY(server.waitForStarted());
  QVERIFY(server.waitForReadyRead());
  const int port=QJsonDocument::fromJson(server.readLine()).object().value("listeningPort").toInt();
  QVERIFY(port>0);
  DisplayClient driver("driver",port,{{"widthPx",1024},{"heightPx",360},{"scale",1},{"outputId","driver"}},dir.filePath("driver.ini"),"","","");
  DisplayClient passenger("passenger",port,{{"widthPx",1024},{"heightPx",360},{"scale",1},{"outputId","passenger"}},dir.filePath("passenger.ini"),"","","");
  QList<QQmlError> warnings;
  QQmlApplicationEngine engine;
  auto *context=engine.rootContext();
  context->setContextProperty("Display",&passenger);
  context->setContextProperty("initialWidth",1024);
  context->setContextProperty("initialHeight",360);
  context->setContextProperty("simulatorReducedMotion",true);
  connect(&engine,&QQmlApplicationEngine::warnings,this,[&](const QList<QQmlError>& errors){warnings+=errors;});
  engine.load(QUrl("qrc:/Main.qml"));
  QVERIFY(!engine.rootObjects().isEmpty());
  auto *window=qobject_cast<QQuickWindow*>(engine.rootObjects().first());
  QVERIFY(window);
  passenger.attachWindow(window);
  window->show();
  QTRY_VERIFY(passenger.state().value("bothReady").toBool());
  const QDir captures(qEnvironmentVariable("MACANOS_QML_TEST_CAPTURES"));
  const auto capture=[&](const QString &name) {
   return !qEnvironmentVariableIsSet("MACANOS_QML_TEST_CAPTURES") ||
          window->grabWindow().save(captures.filePath(name + ".png"));
  };
  const auto click=[&](QQuickItem *item) {
   QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,
     item->mapToScene(QPointF(item->width()/2,item->height()/2)).toPoint());
  };
  auto *displays=window->findChild<QQuickItem*>("displaySettingsButton");
  QVERIFY(displays);
  click(displays);
  auto *bezel=window->findChild<QQuickItem*>("bezelSummary");
  QTRY_VERIFY(bezel&&bezel->isVisible()&&bezel->property("text").toString().endsWith("24 DIP"));
  QVERIFY(capture("display-inventory"));
  click(displays);
  auto *search=window->findChild<QQuickItem*>("searchDestinationButton");
  QVERIFY(search&&search->isVisible()&&search->isEnabled());
  click(search);
  auto *picker=window->findChild<QQuickItem*>("destinationPicker");
  QTRY_VERIFY(picker&&picker->isVisible());
  auto *query=picker->findChild<QQuickItem*>("destinationQuery");
  QTRY_VERIFY(query&&query->hasActiveFocus());
  QTest::keyClick(window,Qt::Key_Escape);
  QTRY_VERIFY(!picker->isVisible());
  click(search);
  QTRY_VERIFY(picker->isVisible()&&query->hasActiveFocus());
  query->setProperty("text","mountain");
  const auto filteredResult=[&]() -> QQuickItem* {
   QList<QQuickItem*> items{picker};
   while(!items.isEmpty()){
    auto *item=items.takeLast();
    if(item->isVisible() && item->property("accessibleLabel").toString()=="Propose Mountain lodge")
     return item;
    items.append(item->childItems());
   }
   return nullptr;
  };
  QTRY_VERIFY(filteredResult());
  QVERIFY(capture("destination-filter"));
  click(filteredResult());
  QTRY_VERIFY(!picker->isVisible());
  const auto pending=[&] {return driver.state().value("model").toMap().value("navigation").toMap().value("pending").toString();};
  QTRY_COMPARE(pending(),QString("Mountain lodge"));
  driver.modeSelect("SHARED");
  QTRY_COMPARE(passenger.mode(),QString("SHARED"));
  driver.setOutputPresent(false);
  QTRY_COMPARE(passenger.mode(),QString("INDEPENDENT"));
  driver.setOutputPresent(true);
  QTRY_VERIFY(passenger.state().value("bothReady").toBool());
  driver.command("model",{{"method","rejectDestination"}});
  QTRY_VERIFY(pending().isEmpty());
  auto *resume=window->findChild<QQuickItem*>("resumeDisplayButton");
  QTRY_VERIFY(resume&&resume->isVisible()&&resume->isEnabled());
  QVERIFY(capture("display-recovery"));
  click(resume);
  QTRY_COMPARE(passenger.mode(),QString("SHARED"));
  QVERIFY(warnings.isEmpty());
  server.terminate();
  QVERIFY(server.waitForFinished());
 }
};
QTEST_MAIN(LayoutTests)
#include "tst_layout.moc"

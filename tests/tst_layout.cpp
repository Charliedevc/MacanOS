// SPDX-License-Identifier: GPL-3.0-or-later
#include <QtTest>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickItem>
#include <QTemporaryDir>
#include "displayclient.h"
class LayoutTests:public QObject {
 Q_OBJECT
private slots:
 void responsive_data(){QTest::addColumn<QString>("role");QTest::addColumn<int>("w");QTest::addColumn<int>("h");for(auto role:{"driver","passenger"})for(auto size:{QSize(1280,480),QSize(1920,720),QSize(1920,1080)})QTest::newRow(qPrintable(QString(role)+QString::number(size.width())+"x"+QString::number(size.height())))<<QString(role)<<size.width()<<size.height();}
 void responsive(){
  QFETCH(QString,role);QFETCH(int,w);QFETCH(int,h);QTemporaryDir dir;DisplayClient client(role,1,{{"widthPx",w},{"heightPx",h},{"scale",1},{"outputId","test"}},dir.filePath("app.ini"),"","","");
  QQmlApplicationEngine engine;QList<QQmlError> warnings;connect(&engine,&QQmlApplicationEngine::warnings,this,[&](const QList<QQmlError> &errors){warnings+=errors;});
  engine.rootContext()->setContextProperty("Display",&client);engine.rootContext()->setContextProperty("initialWidth",w);engine.rootContext()->setContextProperty("initialHeight",h);engine.load(QUrl("qrc:/Main.qml"));QVERIFY(!engine.rootObjects().isEmpty());
  auto *window=qobject_cast<QQuickWindow*>(engine.rootObjects().first());QVERIFY(window);client.attachWindow(window);window->show();QTest::qWait(100);
  QCOMPARE(window->width(),w);QCOMPARE(window->height(),h);auto *panel=window->findChild<QQuickItem*>("primaryPanel");QVERIFY(panel);QVERIFY2(panel->width()>350,qPrintable(QString("Collapsed primary panel: %1").arg(panel->width())));
  for(auto *item:window->findChildren<QQuickItem*>())if(item->objectName()=="action"&&item->isVisible()){
   QVERIFY2(item->height()>=44,"Touch target below 44 DIP");
   const auto bounds=item->mapRectToScene(QRectF(0,0,item->width(),item->height()));
   QVERIFY2(bounds.left()>=0&&bounds.top()>=0&&bounds.right()<=w&&bounds.bottom()<=h,qPrintable(QString("Touch target outside viewport: %1,%2 %3x%4").arg(bounds.x()).arg(bounds.y()).arg(bounds.width()).arg(bounds.height())));
  }
  auto *button=window->findChild<QQuickItem*>(role=="driver"?"mediaButton":"navigationButton");QVERIFY(button);QPointF at=button->mapToScene(QPointF(button->width()/2,button->height()/2));QVERIFY(at.x()>0&&at.x()<w&&at.y()>0&&at.y()<h);
  QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,at.toPoint());QTRY_COMPARE(client.localApp(),role=="driver"?QString("media"):QString("navigation"));
  for(const auto &warning:warnings)qWarning()<<warning;QVERIFY(warnings.isEmpty());
  auto shot=window->grabWindow();QVERIFY(!shot.isNull());QCOMPARE(shot.size(),QSize(w,h));
 }
};
QTEST_MAIN(LayoutTests)
#include "tst_layout.moc"

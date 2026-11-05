// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
Item {
 id: scene
 property var model: ({})
 property string app: "navigation"
 property real clockMs: 0
 readonly property var nav: model.navigation || ({})
 readonly property var media: model.media || ({})
 RouteCanvas { anchors.fill: parent; visible: scene.app==="navigation"; route: scene.nav.route || []; panoramic: true }
 Rectangle { anchors.fill: parent; color: "#11161d"; visible: scene.app==="media" }
 Repeater {
  model: scene.app==="media" ? 120 : 0
  Rectangle {
   required property int index
   readonly property real energy: .2+.8*Math.abs(Math.sin(index*.24+scene.clockMs/1800)*Math.cos(index*.08-scene.clockMs/3100))
   x: index*scene.width/120+2; y: scene.height*.55-height/2
   width: Math.max(2,scene.width/120-5);height: energy*scene.height*.48
   radius: 3;color: index%4===0?"#ef7484":"#753b4d"
  }
 }
 Text { x: 32; y: 106; text: scene.app==="navigation" ? "SCHEMATIC ROUTE / SIMULATED" : "SYNCHRONIZED VISUALIZATION / NO AUDIO"; color: "#92a1af"; font.pixelSize: 12; font.letterSpacing: 2 }
 Text { x: scene.width*.56; y: scene.height*.66; text: scene.app==="navigation" ? (scene.nav.destination || "Destination") : (scene.media.title || "Media"); color: "#f4f5f6"; font.pixelSize: 36; font.weight: Font.Light }
 Text { x: scene.width*.56; y: scene.height*.66+48; text: scene.app==="navigation" ? "18.4 km  ·  24 min  ·  GPS FIXTURE ±8 m" : "MacanOS studio fixtures"; color: "#abb7c3"; font.pixelSize: 16 }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "Theme.js" as Theme
Item {
 id: scene
 property var model: ({})
 property string app: "navigation"
 property real clockMs: 0
 property real viewportX: 0
 property real viewportWidth: width
 readonly property var nav: model.navigation || ({})
 readonly property real barPitch: Math.max(1, width / 120)
 readonly property int firstBar: Math.max(0, Math.floor(viewportX / barPitch))
 readonly property int lastBar: Math.min(120, Math.ceil((viewportX + viewportWidth) / barPitch))
 RouteCanvas { anchors.fill: parent; visible: scene.app==="navigation"; route: scene.nav.route || []; panoramic: true }
 Rectangle { anchors.fill: parent; color: "#11161d"; visible: scene.app==="media" }
 Repeater {
  model: scene.visible && scene.app==="media" ? Math.max(0, scene.lastBar - scene.firstBar) : 0
  Rectangle {
   required property int index
   readonly property int bar: index + scene.firstBar
   readonly property real energy: .2+.8*Math.abs(Math.sin(bar*.24+scene.clockMs/1800)*Math.cos(bar*.08-scene.clockMs/3100))
   id: barItem
   x: bar*scene.barPitch+2
   y: scene.height*.43-height/2
   width: Math.max(2,scene.barPitch-5)
   height: scene.height*.37
   transform: Scale { origin.y: barItem.height / 2; yScale: barItem.energy }
   color: bar%4===0?Theme.accent:"#753b4d"
  }
 }
}

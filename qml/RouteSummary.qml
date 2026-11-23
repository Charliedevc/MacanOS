// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "Theme.js" as Theme

Panel {
 id: summary
 property var navigation: ({})
 property bool live: false
 color: Theme.chrome
 implicitHeight: content.implicitHeight + 20

 Column {
  id: content
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  anchors.margins: 12
  spacing: 3
  Caption { text: "SCHEMATIC ROUTE"; width: parent.width }
  Text {
   text: summary.navigation.destination || "Awaiting simulator"
   color: Theme.text
   font.pixelSize: 23
   width: parent.width
   elide: Text.ElideRight
  }
  Text {
   text: summary.live
    ? summary.navigation.distanceKm + " km  ·  " + summary.navigation.etaMinutes
      + " min  ·  Simulated GPS ±" + summary.navigation.accuracyM + " m"
    : (summary.navigation.destination ? "Last known route · simulator offline" : "Waiting for simulator data")
   color: Theme.secondary
   width: parent.width
   font.pixelSize: 12
   elide: Text.ElideRight
  }
 }
}

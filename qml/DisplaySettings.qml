// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

RowLayout {
 id: page
 property var snapshot: ({})
 property bool online: false
 property string effectiveMode: "INDEPENDENT"
 readonly property var geometry: snapshot.geometry || ({})
 readonly property var displays: snapshot.displays || ({})
 objectName: "displaySettings"
 spacing: 12

 Panel {
  Layout.fillWidth: true
  Layout.fillHeight: true
  ColumnLayout {
   anchors.fill: parent
   anchors.margins: 14
   spacing: 10
   Caption { text: "DISPLAY INVENTORY"; Layout.fillWidth: true }
   Repeater {
    model: ["driver", "passenger"]
    Panel {
     required property string modelData
     readonly property var health: page.displays[modelData] || ({})
     readonly property var viewport: (page.geometry.viewports || ({}))[modelData] || ({})
     Layout.fillWidth: true
     Layout.preferredHeight: 63
     color: Theme.chrome
     Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: 10
      spacing: 4
      Text {
       text: modelData === "driver" ? "Driver" : "Passenger"
       color: Theme.text
       font.pixelSize: 17
      }
      Caption {
       width: parent.width
       text: !page.online || !health.available ? "UNAVAILABLE" :
        viewport.width ? Math.round(viewport.width) + " × " + Math.round(viewport.height) + " DIP · ONLINE" : "ONLINE"
       color: page.online && health.available ? Theme.ready : Theme.warning
      }
     }
    }
   }
   Item { Layout.fillHeight: true }
   Caption { text: "DESKTOP SIMULATION"; Layout.fillWidth: true }
  }
 }
 Panel {
  Layout.fillWidth: true
  Layout.fillHeight: true
  ColumnLayout {
   anchors.fill: parent
   anchors.margins: 14
   spacing: 10
   Caption { text: "CURRENT MODE"; Layout.fillWidth: true }
   Text { text: page.effectiveMode; color: Theme.text; font.pixelSize: 19; Layout.fillWidth: true; elide: Text.ElideRight }
   Text {
    text: page.online && page.snapshot.bothReady
          ? "Both simulated outputs are available."
          : "Shared and Unified require both displays."
    color: Theme.secondary
    font.pixelSize: 13
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
   }
   Caption {
    objectName: "bezelSummary"
    text: "BEZEL GAP  ·  " + (page.online && page.geometry.gapDip !== undefined ? page.geometry.gapDip + " DIP" : "UNAVAILABLE")
    Layout.fillWidth: true
   }
   Item { Layout.fillHeight: true }
   Caption { text: "PHYSICAL GEOMETRY UNVERIFIED"; Layout.fillWidth: true }
  }
 }
}

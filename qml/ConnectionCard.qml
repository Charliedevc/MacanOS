// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Panel {
 id: card
 property string kind: ""
 property string requestedMode: ""
 property bool motion: true
 signal resumeRequested()
 readonly property bool shown: kind !== ""
 objectName: "connectionCard"
 visible: opacity > 0
 enabled: shown
 color: Theme.chrome
 opacity: shown ? 1 : 0
 implicitHeight: body.implicitHeight + 24
 transform: Translate { y: card.motion ? 6 * (1 - card.opacity) : 0 }
 Behavior on opacity { enabled: card.motion; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

 RowLayout {
  id: body
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  anchors.margins: 12
  spacing: 12
  ColumnLayout {
   Layout.fillWidth: true
   spacing: 4
   Caption {
    text: card.kind === "loading" ? "CONNECTING" : card.kind === "offline" ? "DISCONNECTED" : "RECOVERED"
    color: card.kind === "recovered" ? Theme.ready : Theme.warning
    Layout.fillWidth: true
   }
   Text {
    text: card.kind === "loading" ? "Starting MacanOS" :
          card.kind === "offline" ? "Simulator connection lost" : "Both displays detected"
    color: Theme.text
    font.pixelSize: 18
    elide: Text.ElideRight
    Layout.fillWidth: true
   }
   Text {
    text: card.kind === "loading" ? "Waiting for shared data" :
          card.kind === "offline" ? "Independent mode · reconnecting automatically" : "Independent mode remains active"
    color: Theme.secondary
    font.pixelSize: 12
    elide: Text.ElideRight
    Layout.fillWidth: true
   }
   Rectangle {
    id: rail
    visible: card.kind === "loading"
    Layout.fillWidth: true
    Layout.preferredHeight: 2
    color: Theme.border
    Rectangle {
     id: progressBar
     width: rail.width * .28
     height: rail.height
     color: Theme.accent
     SequentialAnimation on x {
      running: rail.visible && card.motion
      loops: Animation.Infinite
      NumberAnimation { from: 0; to: rail.width * .72; duration: 900; easing.type: Easing.InOutSine }
      NumberAnimation { to: 0; duration: 900; easing.type: Easing.InOutSine }
      onRunningChanged: if (!running) progressBar.x = 0
     }
    }
   }
  }
  Action {
   objectName: "resumeDisplayButton"
   visible: card.kind === "recovered" && card.requestedMode !== "" && card.requestedMode !== "INDEPENDENT"
   label: card.requestedMode === "UNIFIED" ? "Resume Unified" : "Resume Shared"
   compact: true
   onActivated: card.resumeRequested()
  }
 }
}

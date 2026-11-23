// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "Theme.js" as Theme

Panel {
 id: picker
 property string pending: ""
 signal proposed(string destination)
 readonly property var destinations: ["Coastal overlook", "City center", "Mountain lodge"]
 objectName: "destinationPicker"
 color: Theme.chrome
 implicitHeight: results.implicitHeight + 20
 onVisibleChanged: {
  if (visible) {
   query.clear()
   query.forceActiveFocus()
  }
 }

 Column {
  id: results
  width: parent.width - 20
  anchors.centerIn: parent
  spacing: 5

  Caption {
   width: parent.width
   text: picker.pending ? "AWAITING DRIVER APPROVAL" : "SIMULATOR DESTINATIONS"
   color: picker.pending ? Theme.warning : Theme.muted
  }
  Panel {
   width: parent.width
   height: 36
   border.color: query.activeFocus ? Theme.accent : Theme.border
   Text {
    anchors.left: parent.left
    anchors.leftMargin: 9
    anchors.verticalCenter: parent.verticalCenter
    visible: query.text.length === 0
    text: "Filter destinations"
    color: Theme.muted
    font.pixelSize: 13
   }
   TextInput {
    id: query
    objectName: "destinationQuery"
    anchors.fill: parent
    anchors.leftMargin: 9
    anchors.rightMargin: 9
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.text
    font.pixelSize: 14
    clip: true
    selectByMouse: true
    Accessible.name: "Filter simulator destinations"
   }
  }
  Repeater {
   id: filtered
   model: picker.destinations.filter(destination => destination.toLowerCase().includes(query.text.trim().toLowerCase()))
   Action {
    required property string modelData
    width: results.width
    label: modelData
    accessibleLabel: "Propose " + modelData
    selected: picker.pending === modelData
    onActivated: picker.proposed(modelData)
   }
  }
  Caption {
   visible: filtered.count === 0
   width: results.width
   text: "NO MATCHING SIMULATOR DESTINATION"
  }
 }
}

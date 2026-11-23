// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "Theme.js" as Theme
Rectangle {
 id: control
 objectName: "action"
 property string label: ""
 property bool selected: false
 property bool compact: false
 property bool narrow: false
 property bool motionEnabled: typeof simulatorReducedMotion === "undefined" || !simulatorReducedMotion
 property string accessibleLabel: label
 signal activated()
 implicitWidth: Math.max(narrow ? 48 : compact ? 72 : 100, text.implicitWidth + (narrow ? 16 : 24))
 implicitHeight: Theme.touch
 radius: 10
 color: tap.pressed ? Theme.pressed : selected ? Theme.selected : Theme.control
 border.color: selected ? Theme.accent : "#363d47"
 Behavior on color { enabled: control.motionEnabled; ColorAnimation { duration: 110 } }
 border.width: 1
 opacity: enabled ? 1 : 0.65
 activeFocusOnTab: true
 Accessible.role: Accessible.Button
 Accessible.name: accessibleLabel
 Accessible.onPressAction: if (enabled) activated()
 Text {
  id: text
  anchors.centerIn: parent
  width: Math.min(implicitWidth, Math.max(0, parent.width - 12))
  text: control.label
  elide: Text.ElideRight
  horizontalAlignment: Text.AlignHCenter
  color: control.enabled ? Theme.text : Theme.secondary
  font.pixelSize: control.narrow ? 12 : 14
  font.weight: Font.Medium
 }
 TapHandler { id: tap; onTapped: control.activated() }
 Keys.onReturnPressed: activated()
 Keys.onSpacePressed: activated()
 Rectangle { anchors.fill: parent; radius: parent.radius; color: "transparent"; border.color: "#fafafa"; visible: control.activeFocus }
}

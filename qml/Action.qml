// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
Rectangle {
 id: control
 objectName: "action"
 property string label: ""
 property bool selected: false
 property bool compact: false
 signal activated()
 implicitWidth: Math.max(compact ? 88 : 116, text.implicitWidth + 28)
 implicitHeight: 44
 radius: 10
 color: tap.pressed ? "#38252a" : selected ? "#3a2228" : "#1e2329"
 border.color: selected ? "#e46270" : "#363d47"
 border.width: 1
 opacity: enabled ? 1 : 0.4
 activeFocusOnTab: true
 Accessible.role: Accessible.Button
 Accessible.name: label
 Text { id: text; anchors.centerIn: parent; text: control.label; color: "#f2f2f3"; font.pixelSize: 13; font.weight: Font.Medium }
 TapHandler { id: tap; onTapped: control.activated() }
 Keys.onReturnPressed: activated()
 Keys.onSpacePressed: activated()
 Rectangle { anchors.fill: parent; radius: parent.radius; color: "transparent"; border.color: "#fafafa"; visible: control.activeFocus }
}

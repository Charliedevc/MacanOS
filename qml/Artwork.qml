// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "Theme.js" as Theme

Rectangle {
 id: artwork
 property string track: ""
 property bool showTitle: false
 radius: Theme.radius
 color: track === "Red horizon" ? "#482a38" : track === "After the rain" ? "#252e48" : "#432842"
 clip: true

 Repeater {
  model: 12
  Rectangle {
   required property int index
   width: Math.max(4, artwork.width / 23)
   height: artwork.height + artwork.width
   x: (index - 2) * artwork.width / 9
   y: (artwork.height - height) / 2
   rotation: 29
   color: index % 3 === 0 ? Theme.accent : "#825177"
   opacity: .72
  }
 }
 Text {
  visible: artwork.showTitle
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.bottom: parent.bottom
  anchors.margins: 12
  text: artwork.track.toUpperCase()
  wrapMode: Text.WordWrap
  maximumLineCount: 2
  elide: Text.ElideRight
  color: Theme.text
  font.pixelSize: Math.max(11, Math.min(24, artwork.width / 8))
  font.letterSpacing: 2
 }
}

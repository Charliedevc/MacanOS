// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "Theme.js" as Theme
Window {
 id: root
 width: initialWidth; height: initialHeight
 minimumWidth: 640; minimumHeight: 360
 color: Theme.background
 title: "MacanOS · " + Display.role
 readonly property bool compact: width < 1080 || height < 420
 readonly property bool narrow: width < 800
 readonly property real unit: Math.max(.84, Math.min(1.22, width/1280, height/480))
 readonly property real edge: compact ? 16 : Theme.edge
 readonly property bool motionEnabled: typeof simulatorReducedMotion === "undefined" || !simulatorReducedMotion
 readonly property bool loading: !Display.online && !snapshot.sessionId
 readonly property var snapshot: Display.state || ({})
 readonly property var model: snapshot.model || ({})
 readonly property var nav: model.navigation || ({})
 readonly property var media: model.media || ({})
 readonly property var vehicle: model.vehicle || ({})
 readonly property var geometry: snapshot.geometry || ({})
 readonly property var viewports: geometry.viewports || ({})
 readonly property var viewport: viewports[Display.role] || ({x:0,y:0,width:width,height:height})
 readonly property var transition: snapshot.transition || ({})
 readonly property real progress: transition.durationMs > 0 ? Math.max(0,Math.min(1,(Display.serverTime-transition.startMs)/transition.durationMs)) : 1
 readonly property bool transitionBusy: Display.online && Display.serverTime < (transition.startMs || 0)+(transition.durationMs || 0)
 readonly property bool beforeCut: motionEnabled && progress < .5
 readonly property string paintedMode: !Display.online ? "INDEPENDENT" : beforeCut ? (transition.fromMode || Display.mode) : Display.mode
 readonly property string paintedApp: paintedMode==="INDEPENDENT" ? Display.localApp : paintedMode==="UNIFIED" ? (beforeCut ? (transition.fromScene || "navigation") : snapshot.unifiedScene) : (beforeCut ? (transition.fromApp || "navigation") : snapshot.sharedApp)
 readonly property bool driver: Display.role==="driver"
 readonly property real blend: Math.abs(2*progress-1)
 readonly property real contentOpacity: !motionEnabled || !Display.online ? 1 : .3+.7*blend*blend*(3-2*blend)
 property real pageOpacity: 1
 onPaintedAppChanged: {
  if (motionEnabled && paintedMode === "INDEPENDENT" && !transitionBusy && Display.online)
   pageEnter.restart()
 }
 NumberAnimation {
  id: pageEnter
  target: root
  property: "pageOpacity"
  from: .48
  to: 1
  duration: 195
  easing.type: Easing.OutCubic
 }
 Item {
  id: visual
  anchors.fill: parent; opacity: root.contentOpacity * root.pageOpacity
  enabled: !root.transitionBusy
  Item {
   anchors.fill: parent;clip: true;visible: root.paintedMode==="UNIFIED"
   Panorama {
    x: -root.viewport.x; y: -root.viewport.y
    width: root.geometry.width || root.width; height: root.geometry.height || root.height
    viewportX: root.viewport.x; viewportWidth: root.viewport.width
    model: root.model; app: root.paintedApp
    clockMs: root.motionEnabled && visible && app === "media" ? Display.serverTime : 0
   }
   Rectangle {
    anchors.left: parent.left; anchors.bottom: parent.bottom
    anchors.leftMargin: root.edge; anchors.bottomMargin: footer.height + root.edge
    width: Math.min(380, parent.width - 2 * root.edge); height: 88
    color: Theme.chrome; radius: Theme.radius; border.color: Theme.border
    Column {
     anchors.fill: parent; anchors.margins: 12; spacing: 3
     Text { text: root.paintedApp === "media" ? "SILENT MEDIA FIXTURE" : "SCHEMATIC ROUTE / SIMULATED"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.1 }
     Text { text: root.paintedApp === "media" ? (root.media.title || "Media") : (root.nav.destination || "Destination"); color: Theme.text; font.pixelSize: 22; width: parent.width; elide: Text.ElideRight }
     Text {
      text: root.paintedApp === "media" ? (root.media.artist || "") :
       (root.nav.distanceKm || 0) + " km  ·  " + (root.nav.etaMinutes || 0) + " min  ·  GPS fixture ±" + (root.nav.accuracyM || 0) + " m"
      color: Theme.secondary
      font.pixelSize: 12
      width: parent.width
      elide: Text.ElideRight
     }
    }
   }
   TapHandler { onTapped: (point)=>Display.touch(point.position.x,point.position.y) }
  }
  RowLayout {
   anchors { left: parent.left; right: parent.right;top: parent.top;bottom: parent.bottom;leftMargin: root.edge;rightMargin:root.edge;topMargin:header.height+root.edge/2;bottomMargin:footer.height+root.edge/2 }
   spacing: root.compact ? 10 : 16
   visible: root.paintedMode!=="UNIFIED"
   ColumnLayout {
    visible: root.driver;Layout.preferredWidth: root.narrow ? 100 : root.compact ? 135 : 166*root.unit;Layout.minimumWidth: Layout.preferredWidth;Layout.maximumWidth: Layout.preferredWidth;Layout.fillHeight: true;spacing:8*root.unit
    Text { text: "SIMULATED SPEED";color:"#82909f";font.pixelSize:11*root.unit;font.letterSpacing:1.5 }
    RowLayout {
     Text { text: Display.online ? Math.round(root.vehicle.speedMph || 0) : "—";color:Theme.text;font.pixelSize:(root.narrow?55:76)*root.unit;font.weight:Font.Light }
     Text { text:"mph";color:"#8996a6";font.pixelSize:15*root.unit;Layout.alignment:Qt.AlignBottom;Layout.bottomMargin:20*root.unit }
    }
    Rectangle { Layout.fillWidth:true;height:3*root.unit;color:"#2b303a";Rectangle { width:parent.width*.38;height:parent.height;color:"#dd6172" } }
    Text { text: Display.online ? Math.round(root.vehicle.rpm || 0)+" rpm" : "RPM unavailable";color:"#c5cdd6";font.pixelSize:16*root.unit }
    Text { text:"VEHICLE FIXTURE";color:"#8a98a8";font.pixelSize:11*root.unit;font.letterSpacing:1.2 }
    Text { text:"Read only";color:"#c7d0db";font.pixelSize:15*root.unit }
   }
   Rectangle {
    objectName:"primaryPanel";Layout.minimumWidth:200;Layout.fillWidth:true;Layout.fillHeight:true;color:Theme.panel;radius:Theme.radius;clip:true;border.color:Theme.border
    RouteCanvas { anchors.fill: parent;visible:root.paintedApp==="navigation";route:root.nav.route || [] }
    Column {
     anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
     anchors.margins: root.compact ? 14 : 22
     spacing:8*root.unit;visible:root.paintedApp==="navigation"
     Text { text:"SCHEMATIC ROUTE / NO LIVE GUIDANCE";color:"#a6b2bd";font.pixelSize:10*root.unit;font.letterSpacing:1.5 }
     Text { text:root.nav.destination || "Awaiting simulator";color:Theme.text;font.pixelSize:30*root.unit;font.weight:Font.Light; width: parent.width; elide: Text.ElideRight }
     Text { text:"18.4 km   ·   24 min   ·   GPS SIMULATED ±8 m";color:"#b5c2cf";font.pixelSize:12*root.unit }
    }
    RowLayout {
     anchors.fill:parent;anchors.margins:root.compact?12:20;spacing:root.compact?12:20;visible:root.paintedApp==="media"
     Rectangle {
      visible: parent.width >= 390
      Layout.preferredWidth:Math.min(196*root.unit,parent.width*.36)
      Layout.preferredHeight:Math.min(Layout.preferredWidth,parent.height)
      Layout.alignment: Qt.AlignVCenter
      radius:Theme.radius;color:"#492632";clip:true
      Repeater { model:12;Rectangle {required property int index;x:parent.width/2-100+index*18;y:-50;width:6;height:450;rotation:28;color:index%3===0?"#df677b":"#74384c";opacity:.8} }
      Text { anchors.left:parent.left;anchors.bottom:parent.bottom;anchors.margins:16;text:"NIGHT\nDRIVE";font.pixelSize:25*root.unit;font.letterSpacing:4;color:"#fff" }
     }
     ColumnLayout {
      Layout.fillWidth:true;Layout.alignment:Qt.AlignVCenter;spacing:root.compact?8:14
      Text { text:"MEDIA STATE SIMULATOR";color:"#91a0b0";font.pixelSize:10*root.unit;font.letterSpacing:1.8 }
      Text { text:root.media.title || "No media";color:"#f1f3f6";font.pixelSize:30*root.unit;elide:Text.ElideRight;Layout.fillWidth:true }
      Text { text:root.media.artist || "";color:"#a8b4c4";font.pixelSize:13*root.unit }
      Rectangle { Layout.fillWidth:true;height:3;color:Theme.border;Rectangle { width:parent.width*(root.media.position||0)/(root.media.duration||248);height:3;color:Theme.accent } }
      RowLayout {
       spacing:10
       Action { label:root.media.playing?"Pause":"Play";onActivated:Display.command("model",{method:"togglePlayback"});enabled:Display.online }
       Action { label:"Next";compact:true;onActivated:Display.command("model",{method:"nextTrack"});enabled:Display.online }
      }
      Text { text:"Shared state · No audible audio";color:"#798b9f";font.pixelSize:11*root.unit }
     }
    }
   }
   ColumnLayout {
    Layout.preferredWidth: root.narrow ? 168 : root.compact ? 194 : (root.driver?216:250)*root.unit
    Layout.minimumWidth: Layout.preferredWidth;Layout.maximumWidth: Layout.preferredWidth;Layout.fillHeight:true;spacing:Theme.gap
    Rectangle {
     Layout.fillWidth:true;Layout.fillHeight:true;radius:Theme.radius;color:Theme.panel;border.color:Theme.border
     ColumnLayout {
      anchors.left:parent.left; anchors.right:parent.right; anchors.top:parent.top
      anchors.margins:root.compact?12:16;spacing:root.compact?6:12
      Text { text:root.driver?"NOW PLAYING":"JOURNEY / FIXTURE";color:"#8292a6";font.pixelSize:10*root.unit;font.letterSpacing:1.6 }
      Text { text:root.driver?(root.media.title||"—"):"Coastal drive";color:"#edf0f5";font.pixelSize:20*root.unit;Layout.fillWidth:true;elide:Text.ElideRight }
      Text { text:root.driver?(root.media.playing?"Playing · Silent fixture":"Paused"):"42.6 mi   ·   54 min";color:"#a3b2c4";font.pixelSize:12*root.unit }
      Rectangle { Layout.fillWidth:true; Layout.preferredHeight:1; color:Theme.border }
      Action { visible:root.driver;label:root.media.playing?"Pause":"Play";enabled:Display.online;onActivated:Display.command("model",{method:"togglePlayback"}) }
      Action { visible:!root.driver;label:root.narrow?"Share center":"Share city center";accessibleLabel:"Share city center";Layout.fillWidth:true;enabled:Display.online;onActivated:Display.command("model",{method:"proposeDestination",destination:"City center"}) }
      Text { text:"Volume " + (root.media.volume || 0) + "%";color:"#a8b7c8";font.pixelSize:12*root.unit }
      Row {
       spacing:8
       Action { label:"−"; narrow:true; accessibleLabel:"Decrease volume"; enabled:Display.online; onActivated:Display.command("model",{method:"setVolume",volume:Math.max(0,(root.media.volume||0)-5)}) }
       Action { label:"+"; narrow:true; accessibleLabel:"Increase volume"; enabled:Display.online; onActivated:Display.command("model",{method:"setVolume",volume:Math.min(100,(root.media.volume||0)+5)}) }
      }
     }
    }
   }
  }
 }
 Rectangle {
  id: header;anchors.left:parent.left;anchors.right:parent.right;height:root.compact?64:72*root.unit;color:Theme.chrome
  RowLayout {
   anchors.fill:parent;anchors.leftMargin:root.edge;anchors.rightMargin:root.edge;spacing:root.narrow?6:Theme.gap
   Column { spacing:3
    Text { text:"M A C A N O S";color:"#f4f5f8";font.pixelSize:17*root.unit;font.weight:Font.Medium }
    Text { text:Display.role.toUpperCase()+" / v0.7 SIMULATOR";color:Theme.muted;font.pixelSize:10; font.letterSpacing: .8 }
   }
   Item { Layout.fillWidth:true }
   Row {
    spacing:6
    Repeater {
     model:["INDEPENDENT","UNIFIED","SHARED"]
     Action {
      required property string modelData
      label: root.narrow && modelData === "INDEPENDENT" ? "SOLO" : modelData
      accessibleLabel: modelData
      selected: Display.mode === modelData; compact:true; narrow:root.narrow
      enabled: Display.online && (!root.transitionBusy || modelData === "INDEPENDENT")
      onActivated: Display.modeSelect(modelData)
     }
    }
   }
   Rectangle { width:1;height:28;color:"#333b46" }
   Action { objectName:"navigationButton";label:root.narrow?"Nav":"Navigation";accessibleLabel:"Navigation";enabled:Display.mode==="INDEPENDENT" || (Display.online && !root.transitionBusy);selected:Display.selectedApp==="navigation";compact:true;narrow:root.narrow;onActivated:Display.selectApp("navigation") }
   Action { objectName:"mediaButton";label:"Media";enabled:Display.mode==="INDEPENDENT" || (Display.online && !root.transitionBusy);selected:Display.selectedApp==="media";compact:true;narrow:root.narrow;onActivated:Display.selectApp("media") }
  }
 }
 Rectangle {
  id: footer
  anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:root.compact?32:38*root.unit;color:Theme.chrome
  RowLayout {
   anchors.fill:parent;anchors.leftMargin:root.edge;anchors.rightMargin:root.edge;spacing:10
   Rectangle {
    width: 8; height: 8; radius: 4
    color: !Display.online || root.snapshot.resumeRequired ? Theme.warning : Theme.ready
    Behavior on color { enabled: root.motionEnabled; ColorAnimation { duration: 180 } }
    opacity: root.motionEnabled && root.loading ? .65+.35*Math.cos(Display.serverTime/220) : 1
   }
   Text { text:root.loading?"CONNECTING TO SIMULATOR":!Display.online?"BACKEND OFFLINE / STALE · INDEPENDENT FALLBACK":root.snapshot.resumeRequired?"DISPLAY RECOVERED · SELECT SAVED MODE TO RESUME":Display.mode==="UNIFIED"?"LOGICAL PANORAMA · CLIPPED VIEWPORT / "+Display.role.toUpperCase():Display.mode==="SHARED"?"SHARED SESSION · ROLE-SPECIFIC LAYOUT":"INDEPENDENT LAYOUT · SHARED SERVICES";color:Theme.secondary;font.pixelSize:11;Layout.fillWidth:true;elide:Text.ElideRight }
   Text { text:root.narrow?"SIMULATED":"SIMULATED · NO VEHICLE CONNECTION";color:"#e38c9b";font.pixelSize:11;font.letterSpacing:.7 }
  }
 }
 Rectangle {
  visible:Display.online && (root.nav.pending || "")!=="";anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:footer.height+root.edge
  width:Math.min(parent.width-48,550*root.unit);height:76;radius:Theme.radius;color:"#252029";border.color:"#ac5b6e"
  RowLayout {
   anchors.fill:parent;anchors.margins:14*root.unit;spacing:12
   Text { text:root.driver?"Approve " + root.nav.pending + "?":"Awaiting driver approval: " + root.nav.pending;color:"#f8edf1";font.pixelSize:14*root.unit;Layout.fillWidth:true;elide:Text.ElideRight }
   Action { visible:root.driver;label:"Approve";compact:true;enabled:Display.online;onActivated:Display.command("model",{method:"approveDestination"}) }
   Action { visible:root.driver;label:"Decline";compact:true;enabled:Display.online;onActivated:Display.command("model",{method:"rejectDestination"}) }
  }
 }
 Rectangle {
  visible: Display.online && Display.message!==""
  anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:header.height+root.edge/2
  width:Math.min(parent.width-48,errorText.implicitWidth+32);height:44;radius:8;color:"#fa35232d";border.color:"#b15d70"
  Text { id:errorText;anchors.centerIn:parent;text:Display.message;color:"#f3dce2";font.pixelSize:12;elide:Text.ElideRight;width:Math.min(implicitWidth,root.width-80) }
 }
}

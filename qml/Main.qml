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
 property bool settingsOpen: false
 property bool destinationOpen: false
 readonly property bool proposalPending: Display.online && Boolean(nav.pending)
 readonly property bool canSearch: !driver && Display.online && !transitionBusy
 readonly property string connectionKind: loading ? "loading" : !Display.online ? "offline" :
     snapshot.resumeRequired && snapshot.bothReady ? "recovered" : ""
 onCanSearchChanged: if (!canSearch) destinationOpen = false
 onPaintedModeChanged: destinationOpen = false
 Shortcut {
  sequence: "Escape"
  enabled: root.settingsOpen || root.destinationOpen
  onActivated: {
   root.settingsOpen = false
   root.destinationOpen = false
  }
 }
 readonly property var snapshot: Display.state || ({})
 readonly property var model: snapshot.model || ({})
 readonly property var nav: model.navigation || ({})
 readonly property var media: model.media || ({})
 readonly property var vehicle: model.vehicle || ({})
 readonly property var geometry: snapshot.geometry || ({})
 readonly property var viewports: geometry.viewports || ({})
 readonly property var viewport: viewports[Display.role] || ({x:0,y:0,width:width,height:height})
 readonly property var transition: snapshot.transition || ({})
 readonly property real transitionEnd: (transition.startMs || 0) + (transition.durationMs || 0)
 readonly property bool transitionPending: Display.online && transition.durationMs > 0 && snapshot.serverMs < transitionEnd
 readonly property real progress: transitionPending ? Math.max(0,Math.min(1,(Display.serverTime-transition.startMs)/transition.durationMs)) : 1
 readonly property bool transitionBusy: transitionPending && progress < 1
 readonly property bool beforeCut: motionEnabled && progress < .5
 readonly property string paintedMode: !Display.online ? "INDEPENDENT" : beforeCut ? (transition.fromMode || Display.mode) : Display.mode
 readonly property string paintedApp: paintedMode==="INDEPENDENT" ? Display.localApp : paintedMode==="UNIFIED" ? (beforeCut ? (transition.fromScene || "navigation") : snapshot.unifiedScene) : (beforeCut ? (transition.fromApp || "navigation") : snapshot.sharedApp)
 readonly property bool driver: Display.role==="driver"
 readonly property real blend: Math.abs(2*progress-1)
 readonly property real contentOpacity: !motionEnabled || !Display.online ? 1 : .3+.7*blend*blend*(3-2*blend)
 property real pageOpacity: 1
 onPaintedAppChanged: {
  destinationOpen = false
  if (motionEnabled && paintedMode === "INDEPENDENT" && !transitionBusy && Display.online && !settingsOpen)
   pageEnter.restart()
 }
 NumberAnimation {
  id: pageEnter
  target: root
  property: "pageOpacity"
  from: .72
  to: 1
  duration: 180
  easing.type: Easing.OutCubic
 }
 Item {
  id: visual
  anchors.fill: parent; opacity: root.contentOpacity * root.pageOpacity
  visible: !root.settingsOpen
  enabled: !root.transitionBusy && visible
  Item {
   anchors.fill: parent;clip: true;visible: root.paintedMode==="UNIFIED"
   Panorama {
    x: -root.viewport.x; y: -root.viewport.y
    width: root.geometry.width || root.width; height: root.geometry.height || root.height
    viewportX: root.viewport.x; viewportWidth: root.viewport.width
    model: root.model; app: root.paintedApp
    clockMs: root.motionEnabled && visible && app === "media" ? Display.serverTime : 0
   }
   RouteSummary {
    visible: root.paintedApp === "navigation"
    anchors.left: parent.left; anchors.bottom: parent.bottom
    anchors.leftMargin: root.edge; anchors.bottomMargin: footer.height + root.edge
    width: Math.min(380, parent.width - 2 * root.edge); height: implicitHeight
    navigation: root.nav
    live: Display.online
   }
   Panel {
    visible: root.paintedApp === "media"
    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
    anchors.margins: root.edge; anchors.bottomMargin: footer.height + root.edge
    height: root.compact ? 77 : 94
    color: Theme.chrome
    RowLayout {
     anchors.fill: parent
     anchors.margins: 10
     spacing: 12
     Artwork {
      Layout.preferredWidth: root.compact ? 54 : 70
      Layout.fillHeight: true
      track: root.media.title || ""
     }
    Column {
     Layout.fillWidth: true
     spacing: 4
     Caption { text: "NOW PLAYING · SILENT FIXTURE"; width: parent.width }
     Text { text: root.media.title || "Media"; color: Theme.text; font.pixelSize: 22; width: parent.width; elide: Text.ElideRight }
    }
    Action { label:root.media.playing?"Pause":"Play"; compact:true; enabled:Display.online; onActivated:Display.command("model",{method:"togglePlayback"}) }
    Action { label:"Next"; compact:true; enabled:Display.online; onActivated:Display.command("model",{method:"nextTrack"}) }
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
   Panel {
    objectName:"primaryPanel";Layout.minimumWidth:200;Layout.fillWidth:true;Layout.fillHeight:true;color:Theme.panel;radius:Theme.radius;clip:true;border.color:Theme.border
    RouteCanvas { anchors.fill: parent;visible:root.paintedApp==="navigation";route:root.nav.route || [] }
    RouteSummary {
     anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
     anchors.margins: root.compact ? 10 : 14
     height: implicitHeight
     visible: root.paintedApp === "navigation" && !root.destinationOpen
     navigation: root.nav
     live: Display.online
    }
    RowLayout {
     anchors.fill:parent;anchors.margins:root.compact?12:20;spacing:root.compact?12:20;visible:root.paintedApp==="media"
     Artwork {
      visible: parent.width >= 390
      Layout.preferredWidth:Math.min(196*root.unit,parent.width*.36)
      Layout.preferredHeight:Math.min(Layout.preferredWidth,parent.height)
      Layout.alignment: Qt.AlignVCenter
      track: root.media.title || ""
      showTitle: true
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
     Panel {
      visible: !root.driver && root.width >= 1000
      Layout.preferredWidth: parent.width * (root.compact ? .36 : .40)
      Layout.fillHeight: true
      clip: true
      RouteCanvas {
       anchors.fill: parent
       route: root.nav.route || []
      }
      RouteSummary {
       anchors.left: parent.left
       anchors.right: parent.right
       anchors.bottom: parent.bottom
       anchors.margins: 8
       height: implicitHeight
       navigation: root.nav
       live: Display.online
      }
     }
    }
   }
   ColumnLayout {
    Layout.preferredWidth: root.narrow ? 168 : root.compact ? 194 : (root.driver?216:250)*root.unit
    Layout.minimumWidth: Layout.preferredWidth;Layout.maximumWidth: Layout.preferredWidth;Layout.fillHeight:true;spacing:Theme.gap
    Panel {
     Layout.fillWidth:true;Layout.fillHeight:true;radius:Theme.radius;color:Theme.panel;border.color:Theme.border
     ColumnLayout {
      anchors.left:parent.left; anchors.right:parent.right; anchors.top:parent.top
      anchors.margins:root.compact?12:16;spacing:root.compact?6:12
      Text { text:root.driver?"NOW PLAYING":"JOURNEY / FIXTURE";color:"#8292a6";font.pixelSize:10*root.unit;font.letterSpacing:1.6 }
      Artwork {
       visible: root.driver && !root.compact && root.paintedApp === "navigation"
       Layout.fillWidth: true
       Layout.preferredHeight: 76
       track: root.media.title || ""
      }
      Text { text:root.driver?(root.media.title||"—"):"Coastal drive";color:"#edf0f5";font.pixelSize:20*root.unit;Layout.fillWidth:true;elide:Text.ElideRight }
      Text { text:root.driver?(root.media.playing?"Playing · Silent fixture":"Paused"):"42.6 mi   ·   54 min";color:"#a3b2c4";font.pixelSize:12*root.unit }
      Rectangle { Layout.fillWidth:true; Layout.preferredHeight:1; color:Theme.border }
      Action { visible:root.driver;label:root.media.playing?"Pause":"Play";enabled:Display.online;onActivated:Display.command("model",{method:"togglePlayback"}) }
      Action {
       objectName: "searchDestinationButton"
       visible: !root.driver
       label: root.destinationOpen ? "Close search" : root.narrow ? "Destinations" : "Search destinations"
       accessibleLabel: root.destinationOpen ? "Close search" : "Search destinations"
       selected: root.destinationOpen
       Layout.fillWidth: true
       enabled: root.canSearch
       onActivated: root.destinationOpen = !root.destinationOpen
      }
      Caption {
       visible: !root.driver && root.proposalPending
       text: "AWAITING APPROVAL"
       color: Theme.warning
       Layout.fillWidth: true
      }
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
  DestinationPicker {
   visible: root.destinationOpen && root.canSearch && root.paintedMode !== "UNIFIED"
   anchors.left: parent.left; anchors.top: parent.top
   anchors.leftMargin: root.edge + 10; anchors.topMargin: header.height + root.edge
   width: Math.min(320, parent.width - 210)
   height: implicitHeight
   pending: root.nav.pending || ""
   onProposed: destination => {
    Display.command("model", {method:"proposeDestination", destination:destination})
    root.destinationOpen = false
   }
  }
 }
 DisplaySettings {
  visible: root.settingsOpen
  anchors.fill: parent
  anchors.margins: root.edge
  anchors.topMargin: header.height + root.edge / 2
  anchors.bottomMargin: footer.height + root.edge / 2
  snapshot: root.snapshot
  online: Display.online
  effectiveMode: Display.mode
 }
 Rectangle {
  id: header;anchors.left:parent.left;anchors.right:parent.right;height:root.compact?64:72*root.unit;color:Theme.chrome
  RowLayout {
   anchors.fill:parent;anchors.leftMargin:root.edge;anchors.rightMargin:root.edge;spacing:root.narrow?6:Theme.gap
   Column { spacing:3
    Text { text:"M A C A N O S";color:"#f4f5f8";font.pixelSize:17*root.unit;font.weight:Font.Medium }
    Text { text:Display.role.toUpperCase()+" / v0.7.1";color:Theme.muted;font.pixelSize:10; font.letterSpacing: .8 }
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
   Action {
    objectName:"navigationButton"; label:root.narrow?"Nav":"Navigation"; accessibleLabel:"Navigation"
    enabled:Display.mode==="INDEPENDENT" || (Display.online && !root.transitionBusy)
    selected:!root.settingsOpen && Display.selectedApp==="navigation"
    compact:true; narrow:root.narrow
    onActivated: { root.settingsOpen = false; Display.selectApp("navigation") }
   }
   Action {
    objectName:"mediaButton"; label:"Media"
    enabled:Display.mode==="INDEPENDENT" || (Display.online && !root.transitionBusy)
    selected:!root.settingsOpen && Display.selectedApp==="media"
    compact:true; narrow:root.narrow
    onActivated: { root.settingsOpen = false; Display.selectApp("media") }
   }
   Action {
    objectName: "displaySettingsButton"
    label: root.narrow ? "⚙" : root.settingsOpen ? "Close" : "Displays"
    accessibleLabel: root.settingsOpen ? "Close display settings" : "Display settings"
    selected: root.settingsOpen
    compact: true
    narrow: root.narrow
    onActivated: {
     root.destinationOpen = false
     root.settingsOpen = !root.settingsOpen
    }
   }
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
   }
   Text { text:root.loading?"CONNECTING TO SIMULATOR":!Display.online?"BACKEND OFFLINE / STALE · INDEPENDENT FALLBACK":root.snapshot.resumeRequired?(root.snapshot.bothReady?"DISPLAY RECOVERED · SELECT SAVED MODE TO RESUME":"DISPLAY UNAVAILABLE · INDEPENDENT FALLBACK"):Display.mode==="UNIFIED"?"LOGICAL PANORAMA · CLIPPED VIEWPORT / "+Display.role.toUpperCase():Display.mode==="SHARED"?"SHARED SESSION · ROLE-SPECIFIC LAYOUT":"INDEPENDENT LAYOUT · SHARED SERVICES";color:Theme.secondary;font.pixelSize:11;Layout.fillWidth:true;elide:Text.ElideRight }
   Text { text:root.narrow?"SIMULATED":"SIMULATED · NO VEHICLE CONNECTION";color:"#e38c9b";font.pixelSize:11;font.letterSpacing:.7 }
  }
 }
 ConnectionCard {
  kind: !root.settingsOpen && !root.proposalPending ? root.connectionKind : ""
  motion: root.motionEnabled
  requestedMode: root.snapshot.requestedMode || ""
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.bottom: parent.bottom
  anchors.bottomMargin: footer.height + root.edge
  width: Math.min(530, parent.width - 2 * root.edge)
  height: implicitHeight
  onResumeRequested: Display.modeSelect(requestedMode)
 }
 Panel {
  visible:root.proposalPending && !root.settingsOpen
  anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:footer.height+root.edge
  width:Math.min(parent.width-48,550*root.unit);height:76;radius:Theme.radius;color:"#252029";border.color:"#ac5b6e"
  RowLayout {
   anchors.fill:parent;anchors.margins:14*root.unit;spacing:12
   ColumnLayout {
    Layout.fillWidth: true
    spacing: 3
    Caption { text: root.driver ? "PASSENGER PROPOSAL" : "AWAITING DRIVER APPROVAL"; color: Theme.warning; Layout.fillWidth: true }
    Text { text:root.nav.pending || "";color:Theme.text;font.pixelSize:18;Layout.fillWidth:true;elide:Text.ElideRight }
   }
   Action { visible:root.driver;label:"Approve";selected:true;compact:true;enabled:!root.transitionBusy;onActivated:Display.command("model",{method:"approveDestination"}) }
   Action { visible:root.driver;label:"Decline";compact:true;enabled:!root.transitionBusy;onActivated:Display.command("model",{method:"rejectDestination"}) }
  }
 }
 Rectangle {
  visible: Display.online && Display.message!==""
  anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:header.height+root.edge/2
  width:Math.min(parent.width-48,errorText.implicitWidth+32);height:44;radius:8;color:"#fa35232d";border.color:"#b15d70"
  Text { id:errorText;anchors.centerIn:parent;text:Display.message;color:"#f3dce2";font.pixelSize:12;elide:Text.ElideRight;width:Math.min(implicitWidth,root.width-80) }
 }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
Window {
 id: root
 width: initialWidth; height: initialHeight
 minimumWidth: 640; minimumHeight: 360
 color: "#0b0e12"
 title: "MacanOS · " + Display.role
 readonly property real unit: Math.max(.78,Math.min(width/1280,height/480))
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
 readonly property real pulse: .70+.30*Math.sin(Display.serverTime/900)
 readonly property string paintedMode: !Display.online ? "INDEPENDENT" : progress<.5 ? (transition.fromMode || Display.mode) : Display.mode
 readonly property string paintedApp: paintedMode==="INDEPENDENT" ? Display.localApp : paintedMode==="UNIFIED" ? (progress<.5 ? (transition.fromScene || "navigation") : snapshot.unifiedScene) : (progress<.5 ? (transition.fromApp || "navigation") : snapshot.sharedApp)
 readonly property bool driver: Display.role==="driver"
 readonly property real contentOpacity: progress>=1 ? 1 : .18+.82*Math.abs(2*progress-1)
 Item {
  id: visual
  anchors.fill: parent; opacity: root.contentOpacity
  Item {
   anchors.fill: parent;clip: true;visible: root.paintedMode==="UNIFIED"
   Panorama { x: -root.viewport.x; y: -root.viewport.y; width: root.geometry.width || root.width; height: root.geometry.height || root.height; model: root.model;app: root.paintedApp;clockMs: Display.serverTime }
   TapHandler { onTapped: (point)=>Display.touch(point.position.x,point.position.y) }
  }
  RowLayout {
   anchors { left: parent.left; right: parent.right;top: parent.top;bottom: parent.bottom;leftMargin: 28*root.unit;rightMargin:28*root.unit;topMargin:88*root.unit;bottomMargin:56*root.unit }
   spacing: 20*root.unit
   visible: root.paintedMode!=="UNIFIED"
   ColumnLayout {
    visible: root.driver;Layout.preferredWidth: 172*root.unit;Layout.minimumWidth:172*root.unit;Layout.maximumWidth:172*root.unit;Layout.fillHeight: true;spacing:8*root.unit
    Text { text: "SIMULATED SPEED";color:"#82909f";font.pixelSize:11*root.unit;font.letterSpacing:1.5 }
    RowLayout {
     Text { text: Display.online ? Math.round(root.vehicle.speedMph || 0) : "—";color:"#f4f5f7";font.pixelSize:80*root.unit;font.weight:Font.Light }
     Text { text:"mph";color:"#8996a6";font.pixelSize:15*root.unit;Layout.alignment:Qt.AlignBottom;Layout.bottomMargin:20*root.unit }
    }
    Rectangle { Layout.fillWidth:true;height:3*root.unit;color:"#2b303a";Rectangle { width:parent.width*.38;height:parent.height;color:"#dd6172" } }
    Text { text: Display.online ? Math.round(root.vehicle.rpm || 0)+" rpm" : "RPM unavailable";color:"#c5cdd6";font.pixelSize:16*root.unit }
    Item { Layout.fillHeight:true }
    Text { text:"VEHICLE FIXTURE";color:"#8a98a8";font.pixelSize:11*root.unit;font.letterSpacing:1.2 }
    Text { text:"Read only";color:"#c7d0db";font.pixelSize:15*root.unit }
   }
   Rectangle {
    objectName:"primaryPanel";Layout.minimumWidth:220*root.unit;Layout.fillWidth:true;Layout.fillHeight:true;color:"#151a21";radius:16*root.unit;clip:true;border.color:"#29313b"
    RouteCanvas { anchors.fill: parent;visible:root.paintedApp==="navigation";route:root.nav.route || [] }
    Column {
     x:22*root.unit;y:20*root.unit;spacing:8*root.unit;visible:root.paintedApp==="navigation"
     Text { text:"SCHEMATIC ROUTE / NO LIVE GUIDANCE";color:"#a6b2bd";font.pixelSize:10*root.unit;font.letterSpacing:1.5 }
     Text { text:root.nav.destination || "Awaiting simulator";color:"#f2f4f7";font.pixelSize:28*root.unit;font.weight:Font.Light }
     Text { text:"18.4 km   ·   24 min   ·   GPS SIMULATED ±8 m";color:"#b5c2cf";font.pixelSize:12*root.unit }
    }
    RowLayout {
     anchors.fill:parent;anchors.margins:24*root.unit;spacing:24*root.unit;visible:root.paintedApp==="media"
     Rectangle {
      Layout.preferredWidth:Math.min(180*root.unit,parent.width*.32);Layout.fillHeight:true;radius:10*root.unit;color:"#492632";clip:true
      Repeater { model:12;Rectangle {required property int index;x:parent.width/2-100+index*18;y:-50;width:6;height:450;rotation:28;color:index%3===0?"#df677b":"#74384c";opacity:.8} }
      Text { anchors.left:parent.left;anchors.bottom:parent.bottom;anchors.margins:16;text:"NIGHT\nDRIVE";font.pixelSize:25*root.unit;font.letterSpacing:4;color:"#fff" }
     }
     ColumnLayout {
      Layout.fillWidth:true;Layout.fillHeight:true;spacing:12*root.unit
      Text { text:"MEDIA STATE SIMULATOR";color:"#91a0b0";font.pixelSize:10*root.unit;font.letterSpacing:1.8 }
      Text { text:root.media.title || "No media";color:"#f1f3f6";font.pixelSize:30*root.unit;elide:Text.ElideRight;Layout.fillWidth:true }
      Text { text:root.media.artist || "";color:"#a8b4c4";font.pixelSize:13*root.unit }
      Item { Layout.fillHeight:true }
      Rectangle { Layout.fillWidth:true;height:3;color:"#333945";Rectangle { width:parent.width*(root.media.position||0)/248;height:3;color:"#e07182" } }
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
    Layout.preferredWidth: root.driver?240*root.unit:276*root.unit;Layout.minimumWidth:root.driver?240*root.unit:276*root.unit;Layout.maximumWidth:root.driver?240*root.unit:276*root.unit;Layout.fillHeight:true;spacing:12*root.unit
    Rectangle {
     Layout.fillWidth:true;Layout.fillHeight:true;radius:14*root.unit;color:"#171c24";border.color:"#29323e"
     ColumnLayout {
      anchors.fill:parent;anchors.margins:18*root.unit;spacing:10*root.unit
      Text { text:root.driver?"NOW PLAYING":"JOURNEY / FIXTURE";color:"#8292a6";font.pixelSize:10*root.unit;font.letterSpacing:1.6 }
      Text { text:root.driver?(root.media.title||"—"):"Coastal drive";color:"#edf0f5";font.pixelSize:20*root.unit;Layout.fillWidth:true;elide:Text.ElideRight }
      Text { text:root.driver?(root.media.playing?"Playing · Silent fixture":"Paused"):"42.6 mi   ·   54 min";color:"#a3b2c4";font.pixelSize:12*root.unit }
      Item { Layout.fillHeight:true }
      Action { visible:root.driver;label:root.media.playing?"Pause":"Play";enabled:Display.online;onActivated:Display.command("model",{method:"togglePlayback"}) }
      Action { visible:!root.driver;label:"Share city center";Layout.fillWidth:true;enabled:Display.online;onActivated:Display.command("model",{method:"proposeDestination",destination:"City center"}) }
      Text { text:"Volume " + (root.media.volume || 0) + "%";color:"#a8b7c8";font.pixelSize:12*root.unit }
      Row { spacing:8;Action {label:"−";compact:true;enabled:Display.online;onActivated:Display.command("model",{method:"setVolume",volume:Math.max(0,(root.media.volume||0)-5)})} Action {label:"+";compact:true;enabled:Display.online;onActivated:Display.command("model",{method:"setVolume",volume:Math.min(100,(root.media.volume||0)+5)})} }
     }
    }
   }
  }
 }
 Rectangle {
  id: header;anchors.left:parent.left;anchors.right:parent.right;height:76*root.unit;color:"#ee10141b"
  RowLayout {
   anchors.fill:parent;anchors.leftMargin:28*root.unit;anchors.rightMargin:28*root.unit;spacing:12*root.unit
   Column { spacing:3
    Text { text:"M A C A N O S";color:"#f4f5f8";font.pixelSize:17*root.unit;font.weight:Font.Medium }
    Text { text:Display.role.toUpperCase()+" / v0.6 SIMULATOR";color:"#77889c";font.pixelSize:9*root.unit;font.letterSpacing:1.2 }
   }
   Item { Layout.fillWidth:true }
   Row { spacing:6;Repeater { model:["INDEPENDENT","UNIFIED","SHARED"];Action { required property string modelData;label:modelData;selected:Display.mode===modelData;compact:true;enabled:Display.online && (!root.transitionBusy || modelData==="INDEPENDENT");onActivated:Display.modeSelect(modelData) } } }
   Rectangle { width:1;height:28;color:"#333b46" }
   Action { objectName:"navigationButton";label:"Navigation";enabled:Display.mode==="INDEPENDENT" || (Display.online && !root.transitionBusy);selected:Display.selectedApp==="navigation";compact:true;onActivated:Display.selectApp("navigation") }
   Action { objectName:"mediaButton";label:"Media";enabled:Display.mode==="INDEPENDENT" || (Display.online && !root.transitionBusy);selected:Display.selectedApp==="media";compact:true;onActivated:Display.selectApp("media") }
  }
 }
 Rectangle {
  anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:42*root.unit;color:"#f010141b"
  RowLayout {
   anchors.fill:parent;anchors.leftMargin:28*root.unit;anchors.rightMargin:28*root.unit;spacing:10
   Rectangle { width:6;height:6;radius:3;color:Display.online?"#b4cbbf":"#ef6c7e";opacity:Display.online?1:root.pulse }
   Text { text:!Display.online?"BACKEND OFFLINE / STALE · INDEPENDENT FALLBACK":root.snapshot.resumeRequired?"DISPLAY RECOVERED · SELECT SAVED MODE TO RESUME":Display.mode==="UNIFIED"?"LOGICAL PANORAMA · CLIPPED VIEWPORT / "+Display.role.toUpperCase():Display.mode==="SHARED"?"SHARED SESSION · ROLE-SPECIFIC LAYOUT":"INDEPENDENT LAYOUT · SHARED SERVICES";color:"#98a8bc";font.pixelSize:10*root.unit;Layout.fillWidth:true;elide:Text.ElideRight }
   Text { text:"SIMULATED · NO VEHICLE CONNECTION";color:"#c67c89";font.pixelSize:10*root.unit;font.letterSpacing:.7 }
  }
 }
 Rectangle {
  visible:(root.nav.pending || "")!=="";anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:54*root.unit
  width:Math.min(parent.width-48,550*root.unit);height:78*root.unit;radius:12;color:"#f2252029";border.color:"#ac5b6e"
  RowLayout {
   anchors.fill:parent;anchors.margins:14*root.unit;spacing:12
   Text { text:root.driver?"Approve " + root.nav.pending + "?":"Awaiting driver approval: " + root.nav.pending;color:"#f8edf1";font.pixelSize:14*root.unit;Layout.fillWidth:true;elide:Text.ElideRight }
   Action { visible:root.driver;label:"Approve";compact:true;enabled:Display.online;onActivated:Display.command("model",{method:"approveDestination"}) }
   Action { visible:root.driver;label:"Decline";compact:true;enabled:Display.online;onActivated:Display.command("model",{method:"rejectDestination"}) }
  }
 }
 Rectangle {
  visible: Display.online && Display.message!==""
  anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:82*root.unit
  width:Math.min(parent.width-48,errorText.implicitWidth+32);height:44;radius:8;color:"#fa35232d";border.color:"#b15d70"
  Text { id:errorText;anchors.centerIn:parent;text:Display.message;color:"#f3dce2";font.pixelSize:12;elide:Text.ElideRight;width:Math.min(implicitWidth,root.width-80) }
 }
}

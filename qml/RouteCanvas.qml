// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
Canvas {
 id: map
 property var route: []
 property bool panoramic: false
 onRouteChanged: requestPaint()
 onWidthChanged: requestPaint()
 onHeightChanged: requestPaint()
 onPaint: {
  var c=getContext("2d"); c.reset(); c.fillStyle="#121a20"; c.fillRect(0,0,width,height)
  // Original schematic streets: deliberately not a live map or navigation renderer.
  c.lineWidth=1; c.strokeStyle="#26343d"
  for(var x=-height;x<width+height;x+=94){c.beginPath();c.moveTo(x,0);c.lineTo(x+height*0.5,height);c.stroke()}
  for(var y=50;y<height;y+=65){c.beginPath();c.moveTo(0,y);c.lineTo(width,y-38);c.stroke()}
  c.strokeStyle="#1c2c35";c.lineWidth=40;c.beginPath();c.moveTo(width*.55,0);c.bezierCurveTo(width*.75,height*.3,width*.50,height*.6,width*.7,height);c.stroke()
  if(route.length<2)return
  c.lineJoin="round";c.lineCap="round"
  function draw(){c.beginPath();for(var i=0;i<route.length;i++){var p=route[i];if(i===0)c.moveTo(p.x*width,p.y*height);else c.lineTo(p.x*width,p.y*height)}}
  draw();c.lineWidth=13;c.strokeStyle="#602b36";c.stroke();draw();c.lineWidth=4;c.strokeStyle="#f07788";c.stroke()
  var a=route[0], b=route[1], px=(a.x*.4+b.x*.6)*width,py=(a.y*.4+b.y*.6)*height
  c.fillStyle="#f2f5f7";c.beginPath();c.moveTo(px,py-12);c.lineTo(px+9,py+10);c.lineTo(px,py+6);c.lineTo(px-9,py+10);c.closePath();c.fill()
  var end=route[route.length-1];c.beginPath();c.arc(end.x*width,end.y*height,7,0,Math.PI*2);c.fillStyle="#ed6d7d";c.fill()
 }
}

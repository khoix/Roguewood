extends RefCounted
static func draw_cue(view:Control,c:Vector2,t:float,ink:Color) -> bool:
 var id:String=view.style.item_id
 if id not in ["ball.glow","pin.prism","ball_mod.grip_tape","pin_mod.spotlight","charm.afterimage","charm.laser_level"]:return false
 var d:Dictionary=view.details
 if view.identity:view.draw_texture_rect(view.identity,Rect2(c-Vector2(19,23),Vector2(38,38)),false)
 var caption:=""
 match id:
  "ball.glow":
   view.draw_arc(c,26,PI*.2,PI*(1.2+.4*t),24,ink,3,true)
   caption="+%d MULT"%int(d.get("amount",0))
  "pin.prism":
   for j in 3:
    var a:float=-PI*.75+j*PI*.25
    var at:=c+Vector2(cos(a),sin(a))*(23+5*t)
    var colors:=[Color("93dce2"),Color("bba3de"),Color("f4e6cd")]
    view.draw_polyline(PackedVector2Array([at+Vector2(0,-4),at+Vector2(4,0),at+Vector2(0,4),at+Vector2(-4,0),at+Vector2(0,-4)]),colors[j],2,true)
   caption="+%d VALUE"%int(d.amount) if d.has("amount") else "CURVED"
  "ball_mod.grip_tape":
   for j in 3:view.draw_line(c+Vector2(-28,-14+j*9),c+Vector2(-23,-20+j*9),ink,3,true)
   caption="HOOK x1.4"
  "pin_mod.spotlight":
   view.draw_polyline(PackedVector2Array([c+Vector2(-22,-25),c+Vector2(-28,10),c+Vector2(-9,10)]),ink,2,true)
   caption="+%d MULT"%int(d.amount) if d.has("amount") else "FIRST HIT"
  "charm.afterimage":
   var shift:float=4 if view.still else 11*(1-t)
   view.draw_arc(c+Vector2(-shift,-shift),25,PI*.7,PI*1.8,22,Color("bba3de"),2,true)
   view.draw_arc(c+Vector2(shift,0),25,-PI*.2,PI*.7,22,ink,2,true)
   caption="x%.1f"%float(d.get("amount",1.5))
  "charm.laser_level":
   var count:int=clampi(int(d.get("count",0)),0,10)
   view.draw_line(c+Vector2(-28,-27),c+Vector2(28,-27),ink,2,true)
   for j in count:view.draw_line(c+Vector2(-27+j*6,-30),c+Vector2(-27+j*6,-24),ink,2,true)
   view.draw_circle(c+Vector2(0,-27),3,Color("f4e6cd"))
   caption="%d +%d"%[count,int(d.get("amount",0))]
 view.draw_string(load("res://assets/ui/fonts/PixelifySans.ttf"),c+Vector2(-31,28),caption,HORIZONTAL_ALIGNMENT_CENTER,62,12,ink)
 return true

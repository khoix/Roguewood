extends RefCounted
## Cues read paid event amounts/counts. Identity images never encode a reward.
static func draw_cue(view:Control,c:Vector2,t:float,ink:Color) -> bool:
 var id:String=view.style.item_id
 if id not in ["ball.oilskin","ball.laser","pin.tempo","charm.neon_sign","ball_mod.blacklight","ball_mod.bumper_guard"]:return false
 var details:Dictionary=view.details
 var count:int=clampi(int(details.get("count",0)),0,2)
 var caption:=""
 if view.identity and id!="charm.neon_sign":view.draw_texture_rect(view.identity,Rect2(c-Vector2(19,23),Vector2(38,38)),false)
 match id:
  "ball.oilskin":
   for side in [-1,1]:
    var at:=c+Vector2(side*(23+4*t),-10+14*t)
    view.draw_arc(at,3,0,TAU,10,ink,2)
   caption="OIL HOLD"
  "ball.laser":
   view.draw_line(c+Vector2(-28,-27),c+Vector2(28,-27),ink,2)
   for j in count:view.draw_rect(Rect2(c+Vector2(-9+j*12,-30),Vector2(5,6)),ink)
   caption="+%d MULT"%int(details.get("amount",0)) if details.has("amount") else "ACCURATE"
  "pin.tempo":
   for j in 2:
    var box:=Rect2(c+Vector2(-28+j*47,-22),Vector2(9,32))
    view.draw_rect(box,Color("30323f"))
    view.draw_rect(box,ink,false,1)
    if j<count:
     var height:float=28.0*(1.0 if view.still else minf(1,t*3))
     view.draw_rect(Rect2(box.position+Vector2(2,30-height),Vector2(5,height)),ink)
   caption="%d HIT +%d"%[count,int(details.get("amount",0))]
  "charm.neon_sign":
   view.draw_rect(Rect2(c+Vector2(-29,-25),Vector2(58,42)),Color("262b3e"))
   view.draw_rect(Rect2(c+Vector2(-29,-25),Vector2(58,42)),ink,false,2)
   for j in 2:
    view.draw_string(load("res://assets/ui/fonts/PixelifySans.ttf"),c+Vector2(-24+j*34,12),"R" if j==0 else "W",HORIZONTAL_ALIGNMENT_LEFT,-1,20,ink if j<count else Color("4a4c57"))
   caption="+%d MULT"%int(details.get("amount",0))
  "ball_mod.blacklight":
   for j in 4:
    var a:float=j*PI*.5
    var at:=c+Vector2(cos(a),sin(a))*(23+3*t)
    view.draw_line(at,at+Vector2(cos(a),sin(a))*5,Color("bd9ef1"),3)
   caption="x%.1f"%float(details.get("amount",1.5))
  "ball_mod.bumper_guard":
   var x:float=25-3*sin(t*PI)
   view.draw_polyline(PackedVector2Array([c+Vector2(x,-28),c+Vector2(x,12),c+Vector2(x-8,12)]),ink,4)
   view.draw_polyline(PackedVector2Array([c+Vector2(12,-24),c+Vector2(21,-10),c+Vector2(5,4)]),ink,2)
   caption="-%d MULT"%absi(int(details.amount)) if details.has("amount") else "REBOUND"
 var font:Font=load("res://assets/ui/fonts/PixelifySans.ttf")
 view.draw_string(font,c+Vector2(-31,28),caption,HORIZONTAL_ALIGNMENT_CENTER,62,12,ink)
 return true

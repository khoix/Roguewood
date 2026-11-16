extends RefCounted
const IDS = ["charm.dry_side","charm.lane_reader","consumable.hook_shot","consumable.line_call","charm.bounce_back","charm.straight_money"]
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
static func draw_cue(view: Control, c: Vector2, t: float, ink: Color) -> bool:
 var id: String = view.style.item_id
 if id not in IDS: return false
 var d: Dictionary = view.details
 if view.identity: view.draw_texture_rect(view.identity,Rect2(c-Vector2(18,23),Vector2(36,36)),false)
 var caption := ""
 match id:
  "charm.dry_side":
   view.draw_line(c+Vector2(-26,-23),c+Vector2(-26,12),ink,4,true)
   view.draw_line(c+Vector2(-29,-6),c+Vector2(-21,-6),Color("f4e6cd"),2,true)
   caption = "+%d MULT" % int(d.get("amount",0)) if d.has("amount") else "LEFT 34ft"
  "charm.lane_reader":
   for j in 3: view.draw_rect(Rect2(c+Vector2(21+j*3,-22+j*5),Vector2(2,25-j*5)),ink)
   caption = "x%.1f" % float(d.get("amount",1.5))
  "consumable.hook_shot":
   view.draw_arc(c,26,PI*.8,PI*(1.6+t*.3),20,ink,2,true)
   caption = "HOOK x1.5"
  "consumable.line_call":
   view.draw_line(c+Vector2(-25,-23),c+Vector2(-25,13),ink,2,true)
   caption = "+%d MULT" % int(d.get("amount",0))
  "charm.bounce_back":
   view.draw_polyline(PackedVector2Array([c+Vector2(-28,-20),c+Vector2(-22,9),c+Vector2(-13,-5)]),ink,3,true)
   var coin: Vector2 = c + (Vector2(-28,-20).lerp(Vector2(-22,9),t*2) if t < 0.5 else Vector2(-22,9).lerp(Vector2(-13,-5),(t-0.5)*2))
   view.draw_circle(coin,4,Color("edca7b"))
   view.draw_line(coin-Vector2(0,2),coin+Vector2(0,2),Color("604626"),1)
   caption = "+$%d" % int(d.get("amount",0)) if d.has("amount") else "RESCUED"
  "charm.straight_money":
   var note := Rect2(c+Vector2(-16,-29-4*t),Vector2(32,13))
   view.draw_rect(note,Color("a3c6ad"))
   view.draw_rect(note.grow(-2),Color("36564d"),false,1)
   view.draw_line(note.position+Vector2(16,0),note.position+Vector2(16,13),Color("f4e6cd"),2)
   caption = "+$%d" % int(d.get("amount",0))
 view.draw_string(FONT,c+Vector2(-32,28),caption,HORIZONTAL_ALIGNMENT_CENTER,64,12,ink)
 return true

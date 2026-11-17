extends RefCounted
const IDS = ["pin.compass","charm.split_pattern","charm.dry_run","charm.long_game","charm.second_chance"]
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
static func draw_cue(view: Control, c: Vector2, t: float, ink: Color) -> bool:
 var id: String = view.style.item_id
 if id not in IDS: return false
 if view.identity: view.draw_texture_rect(view.identity,Rect2(c-Vector2(18,25),Vector2(36,36)),false)
 var d: Dictionary = view.details
 var label := ""
 match id:
  "pin.compass":
   var at := c+Vector2(23,-4)
   view.draw_circle(at,8,Color("35223e"))
   view.draw_arc(at,8,0,TAU,16,ink,1.5,true)
   var tip := Vector2.UP.rotated(PI*.25 if view.still else lerpf(-PI*.25,PI*.25,minf(t*2,1))) * 7
   var wing := tip.normalized().orthogonal()*2.5
   view.draw_colored_polygon(PackedVector2Array([at+tip,at+wing,at-wing]),Color("64dacb"))
   view.draw_colored_polygon(PackedVector2Array([at-tip,at+wing,at-wing]),Color("e2ae59"))
   label = "+%d VALUE" % int(d.amount) if d.has("amount") else "COMPASS"
  "charm.split_pattern":
   var gap := 0.0 if view.still else maxf(0,1-t*2)*8
   view.draw_rect(Rect2(c+Vector2(-27-gap,12),Vector2(26,5)),Color("e2ae59"))
   view.draw_rect(Rect2(c+Vector2(1+gap,12),Vector2(26,5)),Color("64dacb"))
   label = "x%.0f" % float(d.amount) if d.has("amount") else "TWO-TONE"
  "charm.dry_run":
   var count := clampi(int(d.get("count",0)),0,10)
   for i in count:
    var group := i/5; var mark := i%5
    var at := c+Vector2(-28+group*31,10)
    if mark == 4: view.draw_line(at+Vector2(-2,8),at+Vector2(24,0),Color("f4e6cd"),2,true)
    else: view.draw_line(at+Vector2(mark*7,0),at+Vector2(mark*7,9),Color("f4e6cd"),2,true)
   label = "+%d MULT" % int(d.amount) if d.has("amount") else "DRY RUN"
  "charm.long_game":
   view.draw_line(c+Vector2(23,13),c+Vector2(23,-19),Color("64dacb"),3,true)
   view.draw_arc(c+Vector2(23,-15),10,PI,PI+(PI*1.2 if view.still else PI*1.2*minf(t*2,1)),12,ink,2,true)
   label = "x%.1f" % float(d.amount) if d.has("amount") else "LONG OIL"
  "charm.second_chance":
   var width := 23.0 if view.still else 6+17*absf(cos(PI*minf(t*2,1)))
   view.draw_rect(Rect2(c+Vector2(-width*.5,11),Vector2(width,9)),ink,false,2)
   view.draw_line(c+Vector2(-width*.5+2,15),c+Vector2(width*.5-2,15),ink,1,true)
   label = "x%.1f" % float(d.amount) if d.has("amount") else "RESCUED"
 view.draw_string(FONT,c+Vector2(-32,30),label,HORIZONTAL_ALIGNMENT_CENTER,64,11,ink)
 return true

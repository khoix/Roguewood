extends RefCounted
const IDS = ["shop_upgrade.trade_in","shop_upgrade.specialist_shelf","ball.comet","charm.metronome","consumable.steady_hand"]
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
static func draw_cue(view: Control, c: Vector2, t: float, ink: Color) -> bool:
 var id: String = view.style.item_id
 if id not in IDS: return false
 if view.identity: view.draw_texture_rect(view.identity,Rect2(c-Vector2(18,24),Vector2(36,36)),false)
 var d: Dictionary = view.details
 var label := ""
 match id:
  "shop_upgrade.trade_in":
   view.draw_rect(Rect2(c+Vector2(-25,-21+5*t),Vector2(8,12)),ink,false,2)
   label = "$%d SALE" % int(d.amount) if d.has("amount") else "TRADE-IN"
  "shop_upgrade.specialist_shelf":
   view.draw_line(c+Vector2(-25,17),c+Vector2(25,17),ink,3,true)
   label = "SPECIALIST"
  "ball.comet":
   for j in 3: view.draw_line(c+Vector2(-30-j*3,8+j*4),c+Vector2(-18,2+j*4),Color(ink,0.7),2,true)
   label = "+%d MULT" % int(d.amount) if d.has("amount") else "ACCURATE"
  "charm.metronome":
   # One settling tick, then the arm stops on the beat. Reduced t is fixed.
   var arm := Vector2(sin(minf(t*3,1.0)*PI)*9 if d.has("amount") else 0.0,-19)
   view.draw_line(c+Vector2(24,14),c+Vector2(24,14)+arm,ink,2,true)
   label = "x%.1f" % float(d.amount) if d.has("amount") else "ON BEAT"
  "consumable.steady_hand":
   view.draw_arc(c,25,0.15,PI-0.15,16,ink,2,true)
   label = "x%.0f" % float(d.amount) if d.has("amount") else "STEADY"
 view.draw_string(FONT,c+Vector2(-32,29),label,HORIZONTAL_ALIGNMENT_CENTER,64,11,ink)
 return true

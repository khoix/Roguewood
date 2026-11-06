extends Control
## Original deterministic House side-space artwork. Never modifies League assets.
var option := 0
var reduced := false
var phase := 0.0
func _ready() -> void:
 mouse_filter=MOUSE_FILTER_IGNORE
func _process(delta:float) -> void:
 if not reduced:phase+=delta*.008
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("101820"))
 var previous:=Vector2.ZERO
 for i in 90:
  var p:=Vector2(fposmod(i*.6180339+(0.0 if reduced else phase),1.0)*size.x,fposmod(i*.4142135,1.0)*size.y)
  if option==1:
   var group:=i/5
   p=Vector2(fposmod(group*.6180339,1.0)*size.x,fposmod(group*.4142135,1.0)*size.y)+Vector2((i%5)*18,sin(i*2.0)*22)
   p.x=fposmod(p.x+(0.0 if reduced else phase*size.x),size.x)
  if option==1 and i%5!=0 and p.distance_to(previous)<size.x*.25:draw_line(previous,p,Color("26434b"),1)
  draw_rect(Rect2(p,Vector2(2,2) if i%4 else Vector2(3,3)),Color("749b9c") if i%4 else Color("e5bc74"))
  previous=p

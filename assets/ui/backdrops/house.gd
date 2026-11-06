extends Control
## Original schematic sky artwork, not an astronomical chart. No League writes.
var option := 0
var reduced := false
var phase := 0.0
# Recognizable stick figures, each composed once. Normalized local coordinates.
const FIGURES = [
 {"name":"Ursa Major / Big Dipper","at":Vector2(.23,.32),"span":Vector2(.11,.16),"points":[Vector2(0,.2),Vector2(.25,.12),Vector2(.48,.3),Vector2(.65,.34),Vector2(1,.12),Vector2(.94,.81),Vector2(.63,1)],"edges":[[0,1],[1,2],[2,3],[3,4],[4,5],[5,6],[6,3]]},
 {"name":"Cassiopeia","at":Vector2(.67,.32),"span":Vector2(.11,.12),"points":[Vector2(0,.12),Vector2(.22,.95),Vector2(.48,.3),Vector2(.72,.82),Vector2(1,0)],"edges":[[0,1],[1,2],[2,3],[3,4]]},
 {"name":"Orion","at":Vector2(.67,.58),"span":Vector2(.11,.27),"points":[Vector2(.2,0),Vector2(.9,.12),Vector2(.36,.46),Vector2(.5,.5),Vector2(.64,.54),Vector2(.12,.94),Vector2(.93,1),Vector2(.5,.76)],"edges":[[0,1],[0,2],[1,4],[2,3],[3,4],[2,5],[4,6],[5,6],[3,7]]},
 {"name":"Cygnus","at":Vector2(.23,.62),"span":Vector2(.11,.23),"points":[Vector2(.55,0),Vector2(.5,.38),Vector2(.44,.72),Vector2(.4,1),Vector2(0,.3),Vector2(1,.48)],"edges":[[0,1],[1,2],[2,3],[4,1],[1,5]]}
]
func _ready() -> void:mouse_filter=MOUSE_FILTER_IGNORE
func _process(delta:float) -> void:
 if not reduced:phase+=delta*.008
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("101820"))
 var drift:=0.0 if reduced else phase
 # Two hundred and forty small stars, with most kept dim to protect UI contrast.
 for i in 240:
  var p:=Vector2(fposmod(i*.6180339+drift,1.0)*size.x,fposmod(i*.4142135,1.0)*size.y)
  var extent:=Vector2(2,2) if i%11 else Vector2(3,3)
  draw_rect(Rect2(p,extent),Color("48676d") if i%5 else Color("a7bfc0"))
 if option!=1:return
 for figure in FIGURES:
  var points:PackedVector2Array=[]
  # The entire figure moves together. Small bounded displacement avoids wrap lines.
  var offset:=Vector2(sin(drift)*.018,cos(drift)*.009-.009)
  for point in figure.points:points.append((figure.at+point*figure.span+offset)*size)
  for edge in figure.edges:draw_line(points[edge[0]],points[edge[1]],Color("385961"),1)
  for point in points:
   draw_rect(Rect2(point-Vector2(1,1),Vector2(3,3)),Color("e5bc74"))

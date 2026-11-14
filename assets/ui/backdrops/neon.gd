extends Control
## Original Neon flank architecture. Quiet drift, no flashing; centre stays empty.
@export var reduced:=false
var phase:=0.0
func _ready() -> void:mouse_filter=MOUSE_FILTER_IGNORE
func _process(delta:float) -> void:
 if not reduced:phase+=delta*.018
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("101820"))
 var drift:=0.0 if reduced else sin(phase)*4.0
 var unit:=maxf(1.0,floorf(size.x/780.0))
 for side in [-1,1]:
  for i in 5:
   var x:float=(.025+i*.036)*size.x
   if side==1:x=size.x-x
   var y:float=(.12+i*.12)*size.y+drift*unit
   var height:float=size.y*(.15+float(i%2)*.10)
   var width:float=minf((12+i*3)*unit,size.x*.025)
   var end_x:float=x+width*(-side)
   var points:=PackedVector2Array([Vector2(x,y+height),Vector2(x,y+6*unit),Vector2(x+6*unit*(-side),y),Vector2(end_x,y)])
   draw_polyline(points,Color("20373f"),4*unit)
   draw_polyline(points,Color("35545b") if i%2==0 else Color("40344f"),unit)
   draw_rect(Rect2(Vector2(x-2*unit,y+height),Vector2(4*unit,4*unit)),Color("71604b"))
 # Fixed lower stepped lines tie the flank to the room's brass architecture.
 for side in [0,1]:
  var x:float=size.x*.02 if side==0 else size.x*.82
  draw_line(Vector2(x,size.y*.92),Vector2(x+size.x*.16,size.y*.92),Color("343644"),unit)

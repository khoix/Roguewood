extends RefCounted
## E22-L02-ART. Cosmetic drawing only; callers supply existing gameplay boundaries.
const Lane=preload("res://src/simulation/lane_spec.gd")
const INK=Color("101820")
const IVORY=Color("f4e6cd")
const BRASS=Color("c6a468")
const CYAN=Color("70c9cd")

static func rails(canvas:CanvasItem, project:Callable, edge:float, scale:float=1.0) -> void:
 for side in [-1.0,1.0]:
  var inside:Vector2=project.call(Lane.world(side*edge,Lane.BALL_START_F,.002))
  var far_inside:Vector2=project.call(Lane.world(side*edge,Lane.HEAD_PIN_F-.6,.002))
  var outside:Vector2=project.call(Lane.world(side*Lane.LANE_HALF_WIDTH,Lane.BALL_START_F,.002))
  var far_outside:Vector2=project.call(Lane.world(side*Lane.LANE_HALF_WIDTH,Lane.HEAD_PIN_F-.6,.002))
  canvas.draw_colored_polygon(PackedVector2Array([inside,far_inside,far_outside,outside]),Color(.09,.13,.19,.75))
  canvas.draw_line(inside,far_inside,INK,7*scale,true)
  canvas.draw_line(inside,far_inside,BRASS,3*scale,true)
  # Inset enamel rail plus repeated transverse caps: a physical edge, not a laser.
  canvas.draw_line(inside.lerp(outside,.28),far_inside.lerp(far_outside,.28),CYAN,scale,true)
  for i in 17:
   var f:float=lerpf(Lane.BALL_START_F,Lane.HEAD_PIN_F-.6,float(i)/16)
   var a:Vector2=project.call(Lane.world(side*edge,f,.002))
   var b:Vector2=project.call(Lane.world(side*(edge+Lane.BOARD_WIDTH),f,.002))
   canvas.draw_line(a,b,IVORY,2*scale,true)

static func zones(canvas:CanvasItem, pixels:float, zone_scale:float) -> void:
 # Ring timing thresholds come from LaneSpec, including the 0.06 floor.
 # Draw in the caller's flattened ring transform; never change the contracting ring.
 var inner:=Lane.ZONE_FLOOR*pixels
 var perfect:=Lane.perfect_ring(zone_scale)*pixels
 var sweet:=Lane.sweet_ring(zone_scale)*pixels
 canvas.draw_arc(Vector2.ZERO,perfect,0,TAU,48,INK,5,true)
 canvas.draw_arc(Vector2.ZERO,perfect,0,TAU,48,IVORY,1.5,true)
 for i in 12:
  var start:=i*TAU/12
  canvas.draw_arc(Vector2.ZERO,sweet,start,start+TAU/20,6,INK,5,true)
  canvas.draw_arc(Vector2.ZERO,sweet,start,start+TAU/20,6,BRASS,1.5,true)
 # Four inward teeth distinguish the tight perfect band without colour or flashing.
 for i in 4:
  var direction:=Vector2.from_angle(i*PI/2)
  canvas.draw_line(direction*inner,direction*perfect,IVORY,2,true)

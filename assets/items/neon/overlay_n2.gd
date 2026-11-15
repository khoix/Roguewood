extends Node3D
## Cosmetic attachments, no colliders or physics writes.
@export var item_id:=""
var host_id:=""
var lit:=false
var lens:MeshInstance3D
func _ready() -> void:
 name="ModificationOverlay"
 if item_id=="ball_mod.grip_tape":
  var ring:=TorusMesh.new();ring.inner_radius=.098;ring.outer_radius=.112;ring.rings=40;ring.ring_segments=6
  var band:=_mesh(ring,Vector3.ZERO,Color("282842"));band.rotation.z=.65
  for i in 5:
   var tick:=BoxMesh.new();tick.size=Vector3(.003,.014,.006)
   var angle:float=.3+i*.15
   _mesh(tick,Vector3(sin(angle)*.111,0,cos(angle)*.111),Color("82c3cf"))
 elif item_id=="pin_mod.spotlight":
  var clamp:=TorusMesh.new();clamp.inner_radius=.029;clamp.outer_radius=.034;clamp.rings=20;clamp.ring_segments=6
  _mesh(clamp,Vector3(0,.285,0),Color("a4afb2"))
  var housing:=CylinderMesh.new();housing.top_radius=.018;housing.bottom_radius=.021;housing.height=.034
  var body:=_mesh(housing,Vector3(.039,.3,.023),Color("39354c"));body.rotation.x=PI*.5
  var glass:=CylinderMesh.new();glass.top_radius=.016;glass.bottom_radius=.016;glass.height=.003
  lens=_mesh(glass,Vector3(.039,.3,.043),Color("786f59"));lens.rotation.x=PI*.5
func _mesh(mesh:Mesh,at:Vector3,color:Color) -> MeshInstance3D:
 var node:=MeshInstance3D.new();node.mesh=mesh;node.position=at
 var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.45;material.metallic=.3
 node.material_override=material;add_child(node);return node
func set_lit(value:bool) -> void:
 lit=value
 if lens!=null:
  lens.material_override.albedo_color=Color("f4e6cd") if lit else Color("786f59")
  lens.material_override.emission_enabled=lit
  lens.material_override.emission=Color("e7bc70")
  lens.material_override.emission_energy_multiplier=.35

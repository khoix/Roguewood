extends Node3D
## Cosmetic attachment resources. Hosts and collision shapes remain untouched.
@export var item_id:=""
var host_id:=""
var lit:=false
var accents:Array[MeshInstance3D]=[]
func _ready() -> void:
 name="ModificationOverlay"
 if item_id=="ball_mod.blacklight":
  for side in [-1,1]:
   var ring:=TorusMesh.new();ring.inner_radius=.105;ring.outer_radius=.108;ring.rings=32;ring.ring_segments=6
   _mesh(ring,Vector3(0,side*.017,0),Color("7356a5"))
 elif item_id=="ball_mod.bumper_guard":
  # Three small rubber brackets leave the ball's own markings and holes exposed.
  for angle in [0.0,2.1,4.2]:
   var patch:=BoxMesh.new();patch.size=Vector3(.025,.012,.036)
   var at:=Vector3(sin(angle)*.102,-.018,cos(angle)*.102)
   var node:=_mesh(patch,at,Color("3a6466"));node.rotation.y=angle
func _mesh(mesh:Mesh,at:Vector3,color:Color) -> MeshInstance3D:
 var node:=MeshInstance3D.new();node.mesh=mesh;node.position=at
 var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.45;mat.emission_enabled=true;mat.emission=color;mat.emission_energy_multiplier=.12
 node.material_override=mat;add_child(node);accents.append(node);return node
func set_lit(value:bool) -> void:
 lit=value
 for node in accents:
  node.material_override.emission_energy_multiplier=.65 if lit else .12

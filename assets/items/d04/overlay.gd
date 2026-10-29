extends Node3D
## Small original cosmetic attachment; never owns a collider or touches the host.
var item_id := ""
var host_id := ""
const BRASS := Color("bd934f")
func _ready() -> void:
 name="ModificationOverlay"
 match item_id:
  "pin_mod.brass_cap":
   if host_id=="pin.crown":
    _plate([Vector2(-.022,.012),Vector2(.022,.012),Vector2(.026,-.010),Vector2(-.026,-.010)],.28,.037,BRASS)
   else:
    var dome:=SphereMesh.new();dome.radius=.034;dome.height=.046
    _mesh(dome,Vector3(0,.369,0),BRASS)
    var rim:=TorusMesh.new();rim.inner_radius=.029;rim.outer_radius=.035;rim.rings=24;rim.ring_segments=8
    _mesh(rim,Vector3(0,.359,0),BRASS)
  "pin_mod.gilt_leaf":
   _decal(item_id,.18,.063,Vector2(.070,.075))
  "pin_mod.keystone":
   _decal(item_id,.16,.063,Vector2(.070,.059))
  "ball_mod.chalk_grip":
   for i in 7:
    var angle:=1.0+i*.5
    var fleck:=SphereMesh.new();fleck.radius=.0024;fleck.height=.0048
    _mesh(fleck,_ball_surface(-.028+cos(angle)*.017,.045+sin(angle)*.017),Color("f0e6ce"))
  "ball_mod.spin_wax":
   for y in [-.030,-.043]:
    for i in 5:
     var x:float=-.025+i*.010
     var a:=_ball_surface(x,y+.006*cos(x*35))
     var b:=_ball_surface(x+.007,y+.006*cos((x+.007)*35))
     _stroke(a,b,Color("f4df9b"))
  "ball_mod.coin_slot":
   var patch:=_decal(item_id,0,0,Vector2(.026,.050))
   patch.position=_ball_surface(.055,-.025)
   patch.quaternion=Quaternion(Vector3.BACK,patch.position.normalized())
func _ball_surface(x:float,y:float) -> Vector3:
 var radius:float=preload("res://src/simulation/lane_spec.gd").BALL_RADIUS+.0015
 return Vector3(x,y,sqrt(maxf(.001,radius*radius-x*x-y*y)))
func _stroke(a:Vector3,b:Vector3,color:Color) -> void:
 var mesh:=CylinderMesh.new();mesh.top_radius=.0012;mesh.bottom_radius=.0012;mesh.height=a.distance_to(b)
 var node:=MeshInstance3D.new();node.mesh=mesh;node.position=(a+b)*.5;node.quaternion=Quaternion(Vector3.UP,(b-a).normalized());node.material_override=_mat(color);add_child(node)
func _decal(id:String,y:float,z:float,extent:Vector2) -> MeshInstance3D:
 # Sample the unchanged source through its declared icon atlas view. This tiny
 # host patch adds no in_play contract, collider, full-body recolour or lighting.
 var view:=preload("res://src/presentation/item_assets.gd").slot(id,"icon") as AtlasTexture
 var material:=ShaderMaterial.new();var shader:=Shader.new()
 shader.code="shader_type spatial; render_mode unshaded,cull_disabled; uniform sampler2D source_art:source_color,filter_nearest; uniform vec4 region; void fragment(){vec4 ink=texture(source_art,region.xy+UV*region.zw); ALBEDO=ink.rgb; ALPHA=ink.a; ALPHA_SCISSOR_THRESHOLD=0.12;}"
 material.shader=shader;material.set_shader_parameter("source_art",view.atlas)
 var dimensions:=Vector2(view.atlas.get_size())
 material.set_shader_parameter("region",Vector4(view.region.position.x/dimensions.x,view.region.position.y/dimensions.y,view.region.size.x/dimensions.x,view.region.size.y/dimensions.y))
 var patch:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=extent
 patch.mesh=mesh;patch.position=Vector3(0,y,z);patch.material_override=material;add_child(patch)
 return patch
func _mat(color:Color) -> StandardMaterial3D:
 var m:=StandardMaterial3D.new();m.albedo_color=color;m.metallic=.45;m.roughness=.48;m.cull_mode=BaseMaterial3D.CULL_DISABLED
 m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=.18
 return m
func _mesh(mesh:Mesh,at:Vector3,color:Color) -> void:
 var n:=MeshInstance3D.new();n.mesh=mesh;n.position=at;n.material_override=_mat(color);add_child(n)
func _plate(points:Array,y:float,z:float,color:Color) -> void:
 var poly:=PackedVector2Array(points);var indices:=Geometry2D.triangulate_polygon(poly)
 var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in indices:
  surface.set_normal(Vector3.BACK);surface.add_vertex(Vector3(poly[i].x,y+poly[i].y,z))
 _mesh(surface.commit(),Vector3.ZERO,color)

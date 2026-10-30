extends Node3D
## Cosmetic background and native lettering only. Attach at the lane world origin.
## No collision, simulation, save, score or League state; see manifest/handoff.
@export var asset_id: String
@export var backdrop: AtlasTexture
@export var signage: Resource
func _ready() -> void:
 set_meta("asset_id",asset_id)
 var shader:=Shader.new()
 shader.code="shader_type spatial; render_mode unshaded; uniform sampler2D art:source_color,filter_nearest; uniform vec4 region; void fragment(){ALBEDO=texture(art,region.xy+UV*region.zw).rgb;}"
 var material:=ShaderMaterial.new();material.shader=shader
 material.set_shader_parameter("art",backdrop.atlas)
 var extent:=Vector2(backdrop.atlas.get_size())
 material.set_shader_parameter("region",Vector4(backdrop.region.position.x/extent.x,backdrop.region.position.y/extent.y,backdrop.region.size.x/extent.x,backdrop.region.size.y/extent.y))
 var wall:=MeshInstance3D.new();wall.name="HouseBackdrop";var quad:=QuadMesh.new();quad.size=Vector2(9,6)
 wall.mesh=quad;wall.material_override=material;wall.position=Vector3(0,3,-21);add_child(wall)
 _box("SignBrassFrame",Vector3(2.92,.96,.06),Vector3(0,1.62,-20.80),Color("b79050"))
 _box("SignFace",Vector3(2.80,.84,.07),Vector3(0,1.62,-20.75),Color("10282e"))
 _label("HouseTitle",signage.league_title,Vector3(0,1.79,-20.69),160,.0021)
 _label("DivisionTitle",signage.subtitle,Vector3(0,1.43,-20.69),112,.0020)
func _box(label:String,extent:Vector3,at:Vector3,color:Color) -> void:
 var mesh:=BoxMesh.new();mesh.size=extent
 var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=color
 var node:=MeshInstance3D.new();node.name=label;node.mesh=mesh;node.material_override=material;node.position=at;add_child(node)
func _label(label:String,words:String,at:Vector3,font_size:int,pixel:float) -> void:
 var node:=Label3D.new();node.name=label;node.text=words;node.font_size=font_size;node.pixel_size=pixel
 node.modulate=Color("f4e6cd");node.outline_modulate=Color("101820");node.outline_size=8
 node.no_depth_test=false;node.position=at;add_child(node)

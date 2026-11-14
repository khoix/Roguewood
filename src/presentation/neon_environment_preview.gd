extends Control
## Standalone environment/signage inspector. No live League state or mechanics.
const DIRECTORY="res://assets/leagues/neon/"
const Lane=preload("res://src/simulation/lane_spec.gd")
const Dressing=preload("res://src/presentation/lane_dressing.gd")
const Assets=preload("res://src/presentation/item_assets.gd")
var manifest:Dictionary
var stage_index:=0
var room:Node3D
var world:Node3D
var camera:Camera3D
var viewport:SubViewport
var display:TextureRect
var title:Label
var detail:Label
var previous:Button
var next:Button
var reduced:CheckButton
func _ready() -> void:
 manifest=JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY+"manifest.json"))
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 var background:=ColorRect.new();background.color=Color("101820");background.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(background)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 add_child(margin)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);margin.add_child(column)
 title=Label.new();title.add_theme_font_size_override("font_size",26);column.add_child(title)
 var choices:=HBoxContainer.new();column.add_child(choices)
 previous=Button.new();previous.text="Previous";previous.custom_minimum_size=Vector2(120,48);choices.add_child(previous);previous.pressed.connect(func():select_stage(posmod(stage_index-1,9)))
 next=Button.new();next.text="Next";next.custom_minimum_size=Vector2(120,48);choices.add_child(next);next.pressed.connect(func():select_stage((stage_index+1)%9))
 reduced=CheckButton.new();reduced.text="Reduced motion";reduced.tooltip_text="The environment and signage are static in both modes";column.add_child(reduced)
 display=TextureRect.new();display.texture_filter=TEXTURE_FILTER_NEAREST;display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;display.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;display.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(display)
 detail=Label.new();detail.add_theme_font_size_override("font_size",16);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(detail)
 viewport=SubViewport.new();viewport.size=Vector2i(336,480);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport);display.texture=viewport.get_texture()
 world=Node3D.new();world.name="NeonArtWorld";viewport.add_child(world)
 var lighting:=WorldEnvironment.new();var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("101820");environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("c0d1d3");environment.ambient_light_energy=.65;lighting.environment=environment;world.add_child(lighting)
 var lamp:=DirectionalLight3D.new();lamp.rotation_degrees=Vector3(-65,-30,0);lamp.light_energy=1.4;world.add_child(lamp)
 camera=Camera3D.new();camera.name="InspectionCamera";world.add_child(camera);camera.current=true
 var slab:=BoxMesh.new();slab.size=Vector3(Lane.LANE_HALF_WIDTH*2,.10,23.7)
 var floor_mesh:=MeshInstance3D.new();floor_mesh.name="LaneSurface";floor_mesh.mesh=slab;floor_mesh.position=Vector3(0,-.05,-7.7)
 floor_mesh.material_override=load("res://assets/leagues/house/lane_visual.lane_condition.house_oil.tres");world.add_child(floor_mesh)
 var gutter:=StandardMaterial3D.new();gutter.albedo_color=Color("17363d");gutter.roughness=.7
 for side in [-1,1]:
  var edge:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(.22,.06,23.7);edge.mesh=mesh;edge.material_override=gutter;edge.position=Vector3(side*.66,-.025,-7.7);world.add_child(edge)
 var dresser:=Dressing.new()
 for position in range(1,11):
  var pin:=MeshInstance3D.new();pin.name="Pin%d"%position;pin.mesh=dresser._lathe();pin.material_override=Assets.slot("pin.wood","in_play");var spot:=Lane.spot(position);pin.position=Lane.world(spot.x,spot.y);world.add_child(pin)
 resized.connect(func():call_deferred("_layout"))
 display.resized.connect(func():call_deferred("_layout"))
 select_stage(0);call_deferred("_layout")
func select_stage(index:int) -> void:
 stage_index=clampi(index,0,8)
 if is_instance_valid(room):world.remove_child(room);room.queue_free()
 var row:Dictionary=manifest.stages[stage_index]
 room=load(manifest.assets[row.environment_id]).instantiate();world.add_child(room)
 title.text=row.name
 detail.text=row.art_intent+" · Environment and signage inspector"
func _layout() -> void:
 if camera==null or display.size.x<10 or display.size.y<10:return
 var scale:=2 if size.x>=640 else 1
 viewport.size=Vector2i(maxi(1,int(display.size.x)/scale),maxi(1,int(display.size.y)/scale))
 var landscape:=size.x>size.y
 camera.keep_aspect=Camera3D.KEEP_HEIGHT if landscape else Camera3D.KEEP_WIDTH
 camera.fov=40 if landscape else 52
 camera.position=Vector3(0,3.2,-9.0) if landscape else Vector3(0,3.1,-10.0)
 camera.look_at(Vector3(0,2.6 if landscape else 1.6,-20.0))

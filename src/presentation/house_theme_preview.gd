extends Control
## Standalone art inspector. No live League/run input, rules or persistence.
const DIRECTORY="res://assets/leagues/house/"
const Lane=preload("res://src/simulation/lane_spec.gd")
const Dressing=preload("res://src/presentation/lane_dressing.gd")
const Assets=preload("res://src/presentation/item_assets.gd")
var manifest:Dictionary
var stage_index:=0
var lane_index:=0
var room:Node3D
var world:Node3D
var camera:Camera3D
var floor_mesh:MeshInstance3D
var ball:Node3D
var viewport:SubViewport
var display:TextureRect
var title:Label
var detail:Label
var previous:Button
var next:Button
var lane_choice:OptionButton
var overview:CheckButton
var reduced:CheckButton
var music_button:CheckButton
var volume:HSlider
var music:AudioStreamPlayer
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
 lane_choice=OptionButton.new();lane_choice.custom_minimum_size=Vector2(180,48);choices.add_child(lane_choice)
 for row in manifest.lanes:lane_choice.add_item(row.name)
 lane_choice.item_selected.connect(select_lane)
 var options:=HBoxContainer.new();column.add_child(options)
 overview=CheckButton.new();overview.text="Lane finish";options.add_child(overview);overview.toggled.connect(func(_v):_layout())
 reduced=CheckButton.new();reduced.text="Reduced motion";reduced.tooltip_text="This theme is static in both modes";options.add_child(reduced)
 music_button=CheckButton.new();music_button.text="Music";options.add_child(music_button)
 volume=HSlider.new();volume.min_value=0;volume.max_value=1;volume.step=.05;volume.value=.5;volume.custom_minimum_size=Vector2(110,48);volume.size_flags_horizontal=SIZE_EXPAND_FILL;volume.tooltip_text="Music volume";options.add_child(volume)
 display=TextureRect.new();display.texture_filter=TEXTURE_FILTER_NEAREST;display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;display.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;display.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(display)
 detail=Label.new();detail.add_theme_font_size_override("font_size",16);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(detail)
 viewport=SubViewport.new();viewport.size=Vector2i(336,480);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport);display.texture=viewport.get_texture()
 world=Node3D.new();world.name="HouseArtWorld";viewport.add_child(world)
 var lighting:=WorldEnvironment.new();var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("101820");environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("c0d1d3");environment.ambient_light_energy=.65;lighting.environment=environment;world.add_child(lighting)
 var lamp:=DirectionalLight3D.new();lamp.rotation_degrees=Vector3(-65,-30,0);lamp.light_energy=1.4;world.add_child(lamp)
 camera=Camera3D.new();camera.name="InspectionCamera";world.add_child(camera);camera.current=true
 var slab:=BoxMesh.new();slab.size=Vector3(Lane.LANE_HALF_WIDTH*2,.10,23.7)
 floor_mesh=MeshInstance3D.new();floor_mesh.name="LaneSurface";floor_mesh.mesh=slab;floor_mesh.position=Vector3(0,-.05,-7.7);world.add_child(floor_mesh)
 var gutter:=StandardMaterial3D.new();gutter.albedo_color=Color("17363d");gutter.roughness=.7
 for side in [-1,1]:
  var edge:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(.22,.06,23.7);edge.mesh=mesh;edge.material_override=gutter;edge.position=Vector3(side*.66,-.025,-7.7);world.add_child(edge)
 var dresser:=Dressing.new()
 for position in range(1,11):
  var pin:=MeshInstance3D.new();pin.name="Pin%d"%position;pin.mesh=dresser._lathe();pin.material_override=Assets.slot("pin.wood","in_play");var spot:=Lane.spot(position);pin.position=Lane.world(spot.x,spot.y);world.add_child(pin)
 ball=Node3D.new();ball.name="HouseBall";world.add_child(ball);dresser.dress_ball(ball);Assets.dress_ball(ball,"ball.house")
 music=AudioStreamPlayer.new();music.name="HouseMusic";music.stream=load(manifest.assets[manifest.music.asset_id]);music.volume_db=-18;add_child(music)
 music_button.toggled.connect(func(on):
  if on:music.play()
  else:music.stop())
 volume.value_changed.connect(func(value):music.volume_db=linear_to_db(value*.25) if value>0 else -80)
 resized.connect(func():call_deferred("_layout"))
 display.resized.connect(func():call_deferred("_layout"))
 select_stage(0);select_lane(0);call_deferred("_layout")
func select_stage(index:int) -> void:
 stage_index=clampi(index,0,8)
 if is_instance_valid(room):world.remove_child(room);room.queue_free()
 var row:Dictionary=manifest.stages[stage_index]
 room=load(manifest.assets[row.environment_id]).instantiate();world.add_child(room)
 title.text=row.name
 detail.text=row.art_intent+" · "+manifest.lanes[lane_index].name+" · Art inspector"
func select_lane(index:int) -> void:
 lane_index=clampi(index,0,1);lane_choice.select(lane_index)
 floor_mesh.material_override=load(manifest.assets[manifest.lanes[lane_index].visual_id])
 if title!=null:detail.text=manifest.stages[stage_index].art_intent+" · "+manifest.lanes[lane_index].name+" · Art inspector"
func _layout() -> void:
 if camera==null or display.size.x<10 or display.size.y<10:return
 # One world pixel becomes exactly two native pixels at the reference sizes.
 var scale:=2 if size.x>=640 else 1
 viewport.size=Vector2i(maxi(1,int(display.size.x)/scale),maxi(1,int(display.size.y)/scale))
 var landscape:=size.x>size.y
 camera.keep_aspect=Camera3D.KEEP_WIDTH
 camera.fov=64 if landscape else 52
 if overview.button_pressed:
  camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.2
  camera.position=Vector3(0,8,-Lane.OIL_END_F);camera.look_at(Vector3(0,0,-Lane.OIL_END_F),Vector3(0,0,-1));ball.position=Vector3(.27,Lane.BALL_RADIUS,-11.2)
 else:
  camera.projection=Camera3D.PROJECTION_PERSPECTIVE
  camera.position=Vector3(0,3.2,-9.0) if landscape else Vector3(0,3.1,-10.0)
  camera.look_at(Vector3(0,2.6 if landscape else 1.6,-20.0));ball.position=Vector3(0,Lane.BALL_RADIUS,-12.5)

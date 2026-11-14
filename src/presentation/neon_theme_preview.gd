extends "res://src/presentation/neon_environment_preview.gd"
## Session 2 art inspector. Live League integration is owned by the coordinator.
const RuleArt=preload("res://assets/leagues/neon/rule_overlay.gd")
var view_choice:OptionButton
var lane_choice:OptionButton
var music_button:CheckButton
var volume:HSlider
var music:AudioStreamPlayer
var kit:Control
var flank:Control
var kit_cells:Array[Control]=[]
var lane_index:=0
var view_index:=0
func _ready() -> void:
 super._ready()
 var column:=display.get_parent()
 var choices:=HBoxContainer.new();column.add_child(choices);column.move_child(choices,4)
 view_choice=OptionButton.new();view_choice.custom_minimum_size=Vector2(190,48);choices.add_child(view_choice)
 for text in ["Rooms","Lane finishes","UI kit and trophy"]:view_choice.add_item(text)
 view_choice.item_selected.connect(select_view)
 lane_choice=OptionButton.new();lane_choice.custom_minimum_size=Vector2(180,48);choices.add_child(lane_choice)
 for row in manifest.lanes:lane_choice.add_item(row.name)
 lane_choice.item_selected.connect(select_lane)
 var audio_controls:=HBoxContainer.new();column.add_child(audio_controls);column.move_child(audio_controls,5)
 music_button=CheckButton.new();music_button.text="Music";audio_controls.add_child(music_button)
 volume=HSlider.new();volume.min_value=0;volume.max_value=1;volume.step=.05;volume.value=.5;volume.custom_minimum_size=Vector2(160,48);volume.size_flags_horizontal=SIZE_EXPAND_FILL;volume.tooltip_text="Music volume";audio_controls.add_child(volume)
 music=AudioStreamPlayer.new();music.name="NeonMusic";music.stream=load(manifest.assets[manifest.music.asset_id]);music.volume_db=-18;add_child(music)
 music_button.toggled.connect(func(on):
  if on:music.play()
  else:music.stop())
 volume.value_changed.connect(func(value):music.volume_db=linear_to_db(value*.25) if value>0 else -80)
 kit=Control.new();kit.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(kit);column.move_child(kit,6);kit.hide()
 flank=load(manifest.assets[manifest.flank.normal]).instantiate();kit.add_child(flank)
 reduced.toggled.connect(func(on):flank.reduced=on)
 reduced.tooltip_text="Static lanes and rooms; freezes the UI flank backdrop"
 for kind in ["hud","shop","slip","menu","panel"]:
  var panel:=PanelContainer.new();panel.name=kind;panel.add_theme_stylebox_override("panel",load(manifest.assets[manifest.ui.frames[kind]]));kit.add_child(panel);kit_cells.append(panel)
  var label:=Label.new();label.text={"hud":"NEON  •  DIVISION 5\n700 / 2400   $5","shop":"SHOP\n$5   •   Inspect offer","slip":"FRAME REVIEW\n140 × 5 = 700","menu":"SESSION MENU\nResume  •  Options","panel":"HAND  •  4 CARDS\nCycle  •  Inspect"}[kind]
  label.add_theme_font_override("font",load("res://assets/ui/fonts/PixelifySans.ttf"));label.add_theme_font_size_override("font_size",22)
  label.add_theme_color_override("font_color",Color("101820") if kind=="slip" else Color("f4e6cd"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;panel.add_child(label)
 var trophy:=TextureRect.new();trophy.name="NeonTrophy";trophy.texture=load(manifest.assets["trophy.neon"]);trophy.texture_filter=TEXTURE_FILTER_NEAREST;trophy.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;trophy.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;kit.add_child(trophy);kit_cells.append(trophy)
 kit.resized.connect(_layout_kit)
 select_lane(0);select_view(0)
func select_view(index:int) -> void:
 view_index=index;view_choice.select(index)
 kit.visible=index==2;display.visible=index!=2
 viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED if index==2 else SubViewport.UPDATE_ALWAYS
 lane_choice.disabled=index!=1
 _layout();_layout_kit();_detail()
func select_lane(index:int) -> void:
 lane_index=index;lane_choice.select(index)
 world.get_node("LaneSurface").material_override=load(manifest.assets[manifest.lanes[index].visual_id])
 _detail()
func select_stage(index:int) -> void:
 super.select_stage(index)
 if view_choice!=null:_detail()
func _detail() -> void:
 if detail==null:return
 detail.text=[manifest.stages[stage_index].art_intent,"Long Oil: 47 ft • Two-Tone: left 34 ft / right 40 ft • matte hatch = dry","Neon frames • native text • original trophy • quiet flank drift"][view_index]
func _layout() -> void:
 if camera!=null:camera.projection=Camera3D.PROJECTION_PERSPECTIVE
 super._layout()
 if camera==null or view_index!=1:return
 camera.keep_aspect=Camera3D.KEEP_HEIGHT if size.x>size.y else Camera3D.KEEP_WIDTH
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=6.0 if size.x>size.y else 3.0
 camera.position=Vector3(0,8,-12.3);camera.look_at(Vector3(0,0,-12.3),Vector3(0,0,-1))
func _layout_kit() -> void:
 if kit==null or not kit.visible:return
 var columns:=3 if size.x>size.y else 2
 var rows:=2 if columns==3 else 3
 var cell:=(kit.size-Vector2((columns+1)*20,(rows+1)*20))/Vector2(columns,rows)
 for i in kit_cells.size():
  kit_cells[i].position=Vector2(20,20)+Vector2(i%columns,i/columns)*(cell+Vector2(20,20))
  kit_cells[i].size=cell

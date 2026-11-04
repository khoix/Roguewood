extends Control
## Art compositions only. Controls select specimens; displayed gameplay is static.
const Cards=preload("res://src/presentation/ui_a1_preview.gd")
const Assets=preload("res://src/presentation/item_assets.gd")
const Lane=preload("res://src/simulation/lane_spec.gd")
const Dressing=preload("res://src/presentation/lane_dressing.gd")
const FONT=preload("res://assets/ui/fonts/PixelifySans.ttf")
const KIT="res://assets/ui/house/"
var page:=0
var stage:Control
var tabs:Array[Button]=[]
var panels:Array[Panel]=[]
var labels:Array[Label]=[]
var cards:Array[Control]=[]
var actions:Array[Button]=[]
var factory:Control
var lane_view:TextureRect
var lane_camera:Camera3D
var aim_ball:Node3D
var viewport:SubViewport
var safe_regions:Array[Rect2]=[]
func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 var font_theme:=Theme.new();font_theme.default_font=FONT;theme=font_theme
 var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(bg)
 factory=Cards.new()
 stage=Control.new();add_child(stage)
 for i in 3:
  var tab:=Button.new();tab.text=["Throw","Shop","Frame kit"][i];tab.position=Vector2(24+i*144,16);tab.size=Vector2(132,48)
  tab.add_theme_font_size_override("font_size",24);tab.add_theme_stylebox_override("normal",control_style("panel"));tab.add_theme_stylebox_override("focus",control_style("hud"))
  add_child(tab);tabs.append(tab);tab.pressed.connect(func():select_page(i))
 resized.connect(func():call_deferred("rebuild"));rebuild()
func select_page(index:int) -> void:page=index;rebuild()
func frame(kind:String,rect:Rect2) -> Panel:
 var panel:=Panel.new();panel.position=rect.position;panel.size=rect.size;panel.add_theme_stylebox_override("panel",load(KIT+kind+".tres"));panel.set_meta("kit_kind",kind);stage.add_child(panel);panels.append(panel);return panel
func words(text:String,rect:Rect2,pixels:int=24,ink:Color=Color("f4e6cd")) -> Label:
 var label:=Label.new();label.text=text;label.position=rect.position;label.size=rect.size;label.add_theme_font_size_override("font_size",pixels);label.add_theme_color_override("font_color",ink);stage.add_child(label);labels.append(label);return label
func picture(path:String,rect:Rect2) -> TextureRect:
 return factory.image_at(stage,load(path),rect)
func action(text:String,rect:Rect2) -> Button:
 var button:=Button.new();button.text=text;button.position=rect.position;button.size=rect.size;button.add_theme_font_size_override("font_size",24)
 button.add_theme_stylebox_override("normal",control_style("shop"));button.add_theme_stylebox_override("pressed",control_style("hud"));button.add_theme_stylebox_override("focus",control_style("hud"));stage.add_child(button);actions.append(button)
 button.tooltip_text="Visual specimen; no purchase or gameplay action";return button
func card_at(index:int,at:Vector2) -> void:
 var card:=Control.new();card.position=at;card.size=Vector2(210,300);stage.add_child(card);cards.append(card);factory.populate_card(card,index)
func rebuild() -> void:
 if stage==null:return
 for child in stage.get_children():stage.remove_child(child);child.queue_free()
 panels.clear();labels.clear();cards.clear();actions.clear();safe_regions.clear();factory.labels.clear();factory.art_windows.clear();lane_view=null;viewport=null
 for i in 3:tabs[i].modulate=Color("e7bc70") if i==page else Color.WHITE
 var portrait:=size.y>size.x
 words("ART PREVIEW",Rect2(size.x-220,26,196,28),20,Color("95d9cb"))
 if page==0:throw_page(portrait)
 elif page==1:shop_page(portrait)
 else:kit_page(portrait)
func score(rect:Rect2) -> void:
 frame("hud",rect)
 words("FRAME 1 / 2",Rect2(rect.position+Vector2(22,18),Vector2(190,28)),24,Color("e7bc70"))
 words("560",Rect2(rect.position+Vector2(22,48),Vector2(180,58)),48)
 words("TARGET",Rect2(rect.end-Vector2(190,rect.size.y-18),Vector2(160,28)),20,Color("95d9cb"))
 words("1,200",Rect2(rect.end-Vector2(190,rect.size.y-49),Vector2(160,50)),36)
func slip(rect:Rect2) -> void:
 frame("slip",rect)
 words("LAST FRAME",Rect2(rect.position+Vector2(20,16),Vector2(210,28)),24,Color("573a2e"))
 picture("res://assets/ui/cards/value.svg",Rect2(rect.position+Vector2(20,58),Vector2(32,32)))
 words("70",Rect2(rect.position+Vector2(60,56),Vector2(60,34)),28,Color("101820"))
 picture("res://assets/ui/cards/mult.svg",Rect2(rect.position+Vector2(130,58),Vector2(32,32)))
 words("8",Rect2(rect.position+Vector2(170,56),Vector2(60,34)),28,Color("101820"))
 picture(KIT+"divider.svg",Rect2(rect.position+Vector2(20,102),Vector2(220,16)))
 words("560 BANKED",Rect2(rect.position+Vector2(20,126),Vector2(230,38)),28,Color("101820"))
func throw_page(portrait:bool) -> void:
 if portrait:
  score(Rect2(24,88,672,124));lane_at(Rect2(24,228,672,580))
  words("YOUR HAND",Rect2(34,824,320,32),24,Color("e7bc70"))
  card_at(0,Vector2(33,870));card_at(3,Vector2(255,870));picture("res://assets/ui/cards/back.svg",Rect2(477,870,210,300))
  action("DRAW 3",Rect2(24,1200,260,56));action("END TURN",Rect2(436,1200,260,56))
 else:
  score(Rect2(24,88,420,124));slip(Rect2(24,232,264,188))
  frame("panel",Rect2(24,440,264,152));words("HOUSE LEAGUE\nDivision 1\nRoll 1 of 2",Rect2(46,460,220,110),24)
  lane_at(Rect2(312,232,420,464))
  words("YOUR HAND",Rect2(766,88,460,38),28,Color("e7bc70"))
  card_at(0,Vector2(766,140));card_at(3,Vector2(1000,140))
  frame("panel",Rect2(766,460,444,112));words("DRAW 3   /   DISCARD 1",Rect2(790,492,390,40),24)
  action("DRAW",Rect2(766,600,210,64));action("END TURN",Rect2(1000,600,210,64))
func shop_page(portrait:bool) -> void:
 frame("menu",Rect2(24,88,size.x-48,124));words("THE PRO SHOP",Rect2(48,108,440,52),40,Color("e7bc70"))
 words("HOUSE STOCK",Rect2(48,166,350,28),20,Color("95d9cb"))
 picture("res://assets/ui/cards/money.svg",Rect2(size.x-178,118,40,40));words("24",Rect2(size.x-126,116,84,48),36)
 if portrait:
  frame("shop",Rect2(24,232,672,430));words("EQUIPMENT",Rect2(48,250,390,34),24,Color("e7bc70"))
  card_at(0,Vector2(66,298));card_at(1,Vector2(402,298))
  action("STARTER",Rect2(66,606,210,48));action("$5  BUY",Rect2(402,606,210,48))
  frame("shop",Rect2(24,686,672,430));words("CHARMS & UPGRADES",Rect2(48,704,500,34),24,Color("e7bc70"))
  card_at(2,Vector2(66,750));card_at(4,Vector2(402,750))
  action("$11  BUY",Rect2(66,1058,210,48));action("$8  BUY",Rect2(402,1058,210,48))
  action("$2  REROLL",Rect2(24,1188,300,68));action("TO THE LANES",Rect2(372,1188,324,68))
 else:
  frame("shop",Rect2(24,232,942,434));words("EQUIPMENT",Rect2(48,248,420,38),24,Color("e7bc70"));words("CHARMS & UPGRADES",Rect2(500,248,442,38),24,Color("e7bc70"))
  for i in 4:
   var x:=48+i*226
   card_at([0,1,2,4][i],Vector2(x,294));action(["STARTER","$5  BUY","$11  BUY","$8  BUY"][i],Rect2(x,604,210,48))
  frame("panel",Rect2(988,232,268,178));words("STOCK REFRESH\n\n$2 per reroll",Rect2(1012,252,222,130),24)
  action("$2  REROLL",Rect2(988,440,268,64));action("TO THE LANES",Rect2(988,530,268,64))
func kit_page(portrait:bool) -> void:
 var w:=320 if portrait else 380
 var columns:=2 if portrait else 3
 for i in 5:
  var pos:=Vector2(24+i%columns*(w+24),96+i/columns*290)
  var kind:String=["hud","shop","slip","menu","panel"][i]
  frame(kind,Rect2(pos,Vector2(w,260)))
  var ink:=Color("101820") if kind=="slip" else Color("f4e6cd")
  words(kind.to_upper(),Rect2(pos+Vector2(24,24),Vector2(w-48,40)),32,ink)
  words("0123456789\nValue x Mult\n$24  /  560",Rect2(pos+Vector2(24,84),Vector2(w-48,112)),24,ink)
  picture(KIT+"divider.svg",Rect2(pos+Vector2(24,218),Vector2(w-48,16)))
 var sample:=Vector2(368,676) if portrait else Vector2(832,386)
 picture(KIT+"corner.svg",Rect2(sample,Vector2(64,64)))
 words("PIXELIFY SANS\nSIL OFL 1.1\n\nHouse frame kit",Rect2(sample+Vector2(0,80),Vector2(290,146)),24,Color("e7bc70"))
func lane_at(rect:Rect2) -> void:
 frame("panel",rect);var inner:=Rect2(rect.position+Vector2(12,12),rect.size-Vector2(24,24));safe_regions.append(inner)
 viewport=SubViewport.new();viewport.size=Vector2i(inner.size/2);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;stage.add_child(viewport)
 lane_view=factory.image_at(stage,viewport.get_texture(),inner)
 var world:=Node3D.new();viewport.add_child(world)
 world.add_child(load("res://assets/leagues/house/environment.league.house.division_01.tscn").instantiate())
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("101820");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("c0d1d3");env.environment.ambient_light_energy=.65;world.add_child(env)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-65,-30,0);light.light_energy=1.4;world.add_child(light)
 var floor_mesh:=MeshInstance3D.new();var slab:=BoxMesh.new();slab.size=Vector3(Lane.LANE_HALF_WIDTH*2,.10,23.7);floor_mesh.mesh=slab;floor_mesh.position=Vector3(0,-.05,-7.7);floor_mesh.material_override=load("res://assets/leagues/house/lane_visual.lane_condition.house_oil.tres");world.add_child(floor_mesh)
 var dresser:=Dressing.new()
 for n in range(1,11):
  var pin:=MeshInstance3D.new();pin.mesh=dresser._lathe();pin.material_override=Assets.slot("pin.wood","in_play");var spot:=Lane.spot(n);pin.position=Lane.world(spot.x,spot.y);world.add_child(pin)
 var ball:=Node3D.new();aim_ball=ball;world.add_child(ball);dresser.dress_ball(ball);Assets.dress_ball(ball,"ball.house");ball.position=Vector3(0,Lane.BALL_RADIUS,-12.5)
 var camera:=Camera3D.new();lane_camera=camera;world.add_child(camera);camera.current=true;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.fov=52;camera.position=Vector3(0,2.8,-8);camera.look_at(Vector3(0,.3,-17))

func _exit_tree() -> void:
 if is_instance_valid(factory):factory.free()

func control_style(kind:String) -> StyleBoxTexture:
 var style:StyleBoxTexture=load(KIT+kind+".tres").duplicate()
 style.content_margin_left=12;style.content_margin_right=12
 style.content_margin_top=8;style.content_margin_bottom=8
 return style

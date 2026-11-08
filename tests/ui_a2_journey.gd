extends SceneTree
const Factory=preload("res://src/presentation/ui_a1_preview.gd")
var destination:=""
var failures:Array[String]=[]
var overlays:Array[ColorRect]=[]
var factory:Control
func _initialize() -> void:call_deferred("run")
func check(ok:bool,why:String) -> void:
 if not ok:failures.append(why);printerr("FAIL: "+why)
func capture(label:String) -> Image:
 for i in 3:await process_frame
 if DisplayServer.get_name()=="headless":return null
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 check(image.save_png(destination.path_join(label+".png"))==OK,"capture "+label)
 return image
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 root.size=Vector2i(1200,800);root.content_scale_size=root.size
 var bg:=ColorRect.new();bg.color=Color("101820");bg.size=Vector2(root.size);root.add_child(bg)
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/materials/manifest.json"))
 factory=Factory.new()
 var title:=Label.new();title.text="HOUSE RARITY STUDIES / top: interactive, bottom: reduced";title.position=Vector2(28,20);title.add_theme_font_size_override("font_size",24);bg.add_child(title)
 for row in 2:
  for i in 5:
   var rarity:String=Factory.RARITIES[i]
   var entry:Dictionary=manifest.leagues["league.house"][rarity]
   var card:=Control.new();card.position=Vector2(28+i*232,72+row*324);card.size=Vector2(210,300);bg.add_child(card)
   factory.populate_card(card,i,true)
   var overlay:=ColorRect.new();overlay.size=card.size;overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
   overlay.material=load(entry.reduced if row==1 else entry.overlay).duplicate();card.add_child(overlay);overlays.append(overlay)
   check(load(entry.frame)!=null,"House frame "+rarity)
   check(overlay.material.get_shader_parameter("rarity")==i,"rarity binding")
   check(bool(overlay.material.get_shader_parameter("reduced"))==(row==1),"reduced binding")
 var x:=28
 for id in manifest.icons:
  var icon:=TextureRect.new();icon.position=Vector2(x,736);icon.size=Vector2(32,32);icon.texture=load(manifest.icons[id]);bg.add_child(icon);x+=64
  check(icon.texture!=null and icon.texture.get_size()==Vector2(32,32),"32px icon "+id)
 for overlay in overlays:overlay.material.set_shader_parameter("progress",.15)
 var a:=await capture("phase_a")
 for overlay in overlays:overlay.material.set_shader_parameter("progress",.65)
 var b:=await capture("phase_b")
 if a!=null and b!=null:
  check(a.get_region(Rect2i(0,396,1200,300)).get_data()==b.get_region(Rect2i(0,396,1200,300)).get_data(),"reduced row is pixel-identical despite phase change")
  check(a.get_region(Rect2i(28,72,210,300)).get_data()==b.get_region(Rect2i(28,72,210,300)).get_data(),"common stays matte")
  for i in range(1,5):
   check(a.get_region(Rect2i(28+i*232,72,210,300)).get_data()!=b.get_region(Rect2i(28+i*232,72,210,300)).get_data(),"normal material responds to supplied phase")
  for overlay in overlays:overlay.hide()
  var base:=await capture("base")
  for row in 2:
   for i in 5:
    var origin:=Vector2i(28+i*232,72+row*324)
    for rect in [Rect2i(14,10,182,28),Rect2i(14,226,182,60),Rect2i(17,44,26,26)]:
     var zone:=Rect2i(origin+rect.position,rect.size)
     check(b.get_region(zone).get_data()==base.get_region(zone).get_data(),"foil excludes name/rules/rarity/category")
 else:await capture("base")
 factory.free()
 if "--inject-failure" in OS.get_cmdline_user_args():check(false,"injected failure")
 if failures.is_empty():print("ROGUEWOOD_UI_A2_OK")
 quit(0 if failures.is_empty() else 1)

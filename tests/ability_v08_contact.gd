extends SceneTree
const Assets=preload("res://src/presentation/item_assets.gd")
var destination:=""
func _initialize(): call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="): destination=arg.trim_prefix("--artifact-dir=")
 var rows: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/batches.json"))["E20-V08"]
 var shapes:={}
 var failures:=[]
 for row in rows:
  var recipe=Assets.slot(row[0],"activation")
  var sound=Assets.slot(row[0],"sound")
  if recipe==null or recipe.item_id!=row[0] or sound==null: failures.append("missing declared recipe or audio")
  else: shapes[recipe.shape]=true
 if shapes.size()!=8: failures.append("eight distinct constructions required")
 if DisplayServer.get_name()!="headless" and failures.is_empty():
  root.size=Vector2i(1280,720);root.content_scale_size=root.size
  var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
  for i in rows.size():
   var id: String=rows[i][0]
   var box:=VBoxContainer.new();box.position=Vector2(18+(i%4)*320,16+(i/4)*350);box.custom_minimum_size=Vector2(284,320);box.add_theme_constant_override("separation",20);bg.add_child(box)
   var label:=Label.new();label.text=Assets._items[id].name+"\n"+rows[i][1];label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(label)
   for reduced in [false,true]:
    var glyph: Control=preload("res://src/presentation/ability_glyph.gd").new();glyph.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;box.add_child(glyph)
    var count: int=10 if id=="charm.pin_counter" else 3
    var amount: float=1.5 if id=="charm.banana_ball" else (1.0 if id=="charm.tip_jar" else 5.0)
    glyph.show_cue(Assets.slot(id,"activation"),reduced,Assets.slot(id,"icon"),{"count":count,"amount":amount,"streak":2,"position":3})
    glyph.set_process(false);glyph.age=.25
   var caption:=Label.new();caption.text="64px cue / static reduced\nIllustrative counts";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(caption)
  for i in 12: await process_frame
  await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png(destination.path_join("contact.png"))!=OK: failures.append("capture")
 for failure in failures: printerr("FAIL: ",failure)
 if failures.is_empty(): print("ROGUEWOOD_V08_CONTACT_OK")
 quit(0 if failures.is_empty() else 1)

extends SceneTree
const Assets=preload("res://src/presentation/item_assets.gd")
var destination:=""
func _initialize():call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 var batch:="AV-C03-B" if "av-c03-b" in destination else "AV-C03-A"
 var rows:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/batches.json"))[batch]
 var failures:=[]
 var shapes:={}
 for row in rows:
  var recipe=Assets.slot(row[0],"activation")
  if recipe==null or recipe.item_id!=row[0] or Assets.slot(row[0],"sound")==null:failures.append("exact declared assets missing")
  else:shapes[recipe.shape]=true
 if shapes.size()!=3:failures.append("three distinct constructions")
 if DisplayServer.get_name()!="headless" and failures.is_empty():
  root.size=Vector2i(960,720);root.content_scale_size=root.size
  var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
  for i in rows.size():
   var id:String=rows[i][0]
   var box:=VBoxContainer.new();box.position=Vector2(12+i*320,24);box.custom_minimum_size=Vector2(296,600);box.add_theme_constant_override("separation",22);bg.add_child(box)
   var label:=Label.new();label.text=Assets._items[id].name;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(label)
   for variant in 3:
    var glyph:Control=preload("res://src/presentation/ability_glyph.gd").new();glyph.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;box.add_child(glyph)
    var context:={"count":2,"amount":6,"last_fallen":8,"position":8,"leave":4,"grades":["sweet","perfect"],"positions":[7,9],"match_score":100,"match_target":500,"behind":true}
    if variant==2 and id=="pin.crown":context["zero"]=true;context.position=6
    glyph.show_cue(Assets.slot(id,"activation"),variant>0,Assets.slot(id,"icon"),context)
    glyph.set_process(false);glyph.age=.25
    var caption:=Label.new();caption.text=["64px animated cue","64px reduced/static","Quiet zero" if id=="pin.crown" else "Reduced flash"][variant];caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(caption)
   var note:=Label.new();note.text="Illustrative values";note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;box.add_child(note)
  for i in 12:await process_frame
  await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png(destination.path_join("contact.png"))!=OK:failures.append("contact capture")
 for failure in failures:printerr("FAIL: ",failure)
 if failures.is_empty():print("ROGUEWOOD_AV_C03_CONTACT_OK")
 quit(0 if failures.is_empty() else 1)

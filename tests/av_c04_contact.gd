extends SceneTree
const Assets=preload("res://src/presentation/item_assets.gd")
var destination:=""
func _initialize():call_deferred("run")
func run():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 var batch:="AV-C04-B" if "av-c04-b" in destination else "AV-C04-A"
 var rows:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/batches.json"))[batch]
 var failures:=[];var shapes:={}
 for row in rows:
  var recipe=Assets.slot(row[0],"activation")
  if recipe==null or recipe.item_id!=row[0] or Assets.slot(row[0],"sound")==null:failures.append("exact declared assets missing")
  else:shapes[recipe.shape]=true
  for slot in ["icon","card","rarity_treatment","reduced_motion"]:
   if Assets.slot(row[0],slot)==null:failures.append("missing "+slot)
 if shapes.size()!=3:failures.append("three distinct constructions")
 if DisplayServer.get_name()!="headless" and failures.is_empty():
  root.size=Vector2i(1080,880);root.content_scale_size=root.size
  var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
  for i in rows.size():
   var id:String=rows[i][0]
   var box:=VBoxContainer.new();box.position=Vector2(12+i*356,20);box.custom_minimum_size=Vector2(332,840);box.add_theme_constant_override("separation",16);bg.add_child(box)
   _label(box,Assets._items[id].name)
   _image(box,id,192)
   _label(box,"192px identity / 64px / 32px")
   for extent in [64,32]:
    var strip:=HBoxContainer.new();strip.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;strip.add_theme_constant_override("separation",28);box.add_child(strip)
    for mode in 3:
     var tex:=_image(strip,id,extent)
     if mode>0:
      var shader:=Shader.new()
      shader.code="shader_type canvas_item; void fragment(){vec4 p=texture(TEXTURE,UV); float g=dot(p.rgb,vec3(.299,.587,.114)); COLOR=vec4("+("vec3(g)" if mode==1 else "vec3(.94)")+",p.a);}"
      var material:=ShaderMaterial.new();material.shader=shader;tex.material=material
   _label(box,"Colour / grayscale / silhouette")
   for reduced in [false,true]:
    var glyph:Control=preload("res://src/presentation/ability_glyph.gd").new();glyph.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;box.add_child(glyph)
    glyph.show_cue(Assets.slot(id,"activation"),reduced,Assets.slot(id,"icon"),{"count":10,"amount":{"pin_mod.keystone":40,"ball_mod.chalk_grip":2,"ball_mod.spin_wax":4,"ball_mod.coin_slot":2}.get(id,1)})
    glyph.set_process(false);glyph.age=.25
    _label(box,"Static reduced cue" if reduced else "Animated cue sample")
   _label(box,"Illustrative values; native checks separate")
  for i in 12:await process_frame
  await RenderingServer.frame_post_draw
  if root.get_texture().get_image().save_png(destination.path_join("contact.png"))!=OK:failures.append("contact capture")
 for failure in failures:printerr("FAIL: ",failure)
 if failures.is_empty():print("ROGUEWOOD_AV_C04_CONTACT_OK")
 quit(0 if failures.is_empty() else 1)
func _image(parent:Node,id:String,extent:int) -> TextureRect:
 var tex:=TextureRect.new();tex.texture=Assets.slot(id,"icon");tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;tex.custom_minimum_size=Vector2(extent,extent)
 tex.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;tex.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;parent.add_child(tex);return tex
func _label(parent:Node,words:String) -> void:
 var label:=Label.new();label.text=words;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",16);parent.add_child(label)

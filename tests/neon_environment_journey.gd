extends SceneTree
## Native inspector input and actual rendered resources, independent of live integration.
const Preview=preload("res://src/presentation/neon_environment_preview.tscn")
var app:Control
var destination:=""
var failures:Array[String]=[]
var stage_images:Array[Image]=[]
var report:Dictionary={"stages":[],"checks":[]}
func _initialize():call_deferred("run")
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 root.size=Vector2i(780,1688);root.content_scale_size=root.size
 app=Preview.instantiate();root.add_child(app);await frames(12)
 var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/leagues/neon.json"))
 check(app.manifest.league_id==spec.id,"exact Neon League ID")
 check(app.manifest.stages.size()==9,"eight Divisions plus Championship")
 var stage_assets:={}
 for stage in app.manifest.stages:
  for field in ["environment_id","signage_id","backdrop_id"]:stage_assets[stage[field]]=true
 check(stage_assets.size()==27,"twenty-seven unique environment bindings")
 for id in app.manifest.assets:check(ResourceLoader.exists(app.manifest.assets[id]),"resource exists: "+id)
 var regions:={}
 var pins:={}
 for i in range(1,11):pins[i]=app.world.get_node("Pin%d"%i).transform
 for i in 9:
  var row:Dictionary=app.manifest.stages[i]
  check(app.stage_index==i,"Next selects stage %d"%i)
  check(app.room.asset_id==row.environment_id and app.room.signage.asset_id==row.signage_id,"scene and sign IDs bind")
  check(app.room.backdrop.resource_path==app.manifest.assets[row.backdrop_id],"backdrop ID binds")
  check(app.room.signage.division==mini(i+1,8) and app.room.signage.championship==(i==8),"Division and Championship identity")
  check(app.room.get_node("LeagueTitle").text=="NEON","native League sign")
  check(app.room.get_node("DivisionTitle").text==("CHAMPIONSHIP" if i==8 else "DIVISION %02d"%(i+1)),"native Division sign")
  if i<8:check(row.name==spec.divisions[i].name,"Division name matches League")
  var region:Rect2=app.room.backdrop.region
  check(not regions.has(str(region)),"distinct architectural region")
  regions[str(region)]=true
  check(Rect2(Vector2.ZERO,app.room.backdrop.atlas.get_size()).encloses(region),"atlas region is in bounds")
  check(app.room.find_children("*","CollisionObject3D",true,false).is_empty(),"environment is cosmetic")
  check(app.room.find_children("*","AnimationPlayer",true,false).is_empty(),"environment has no animated lighting")
  check(not "TIME" in app.room.get_node("NeonBackdrop").material_override.shader.code,"backdrop shader is static")
  for pin in pins:check(app.world.get_node("Pin%d"%pin).transform==pins[pin],"stage switch preserves pin %d"%pin)
  await capture("division_%02d"%(i+1) if i<8 else "championship")
  if rendered():stage_images.append(app.viewport.get_texture().get_image())
  report.stages.append({"id":row.environment_id,"sign":app.room.get_node("DivisionTitle").text,"region":str(region)})
  if i<8:await press(app.next)
 await press(app.previous);check(app.stage_index==7,"Previous navigation")
 await press(app.next);check(app.stage_index==8,"Championship navigation")
 await press(app.next);check(app.stage_index==0,"stage wrap")
 await press(app.previous);check(app.stage_index==8,"reverse stage wrap")
 fit("portrait")
 var normal:PackedByteArray
 if rendered():
  await RenderingServer.frame_post_draw
  normal=app.viewport.get_texture().get_image().get_data()
 await press(app.reduced);check(app.reduced.button_pressed,"native reduced-motion control")
 await capture("reduced")
 if rendered():
  check(normal==app.viewport.get_texture().get_image().get_data(),"reduced motion preserves static environment pixels")
  await frames(60);await RenderingServer.frame_post_draw
  check(normal==app.viewport.get_texture().get_image().get_data(),"no flicker across sixty frames")
 root.size=Vector2i(1688,780);root.content_scale_size=root.size;await frames(12)
 fit("landscape");await capture("landscape")
 if rendered():await contact()
 report.failures=failures
 var file:=FileAccess.open(destination.path_join("report.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "));file.close()
 for failure in failures:printerr("FAIL: ",failure)
 if failures.is_empty():print("ROGUEWOOD_NEON_ENVIRONMENT_OK stages=9 assets=27 static=true")
 app.queue_free();app=null;await frames(4)
 quit(0 if failures.is_empty() else 1)
func fit(orientation:String) -> void:
 for control in [app.previous,app.next,app.reduced,app.title,app.detail]:
  check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(control.get_global_rect()),orientation+" control fits: "+control.get_class())
 var bounds:=Rect2(Vector2.ZERO,Vector2(app.viewport.size))
 for x in [-4.5,4.5]:
  for y in [0.0,6.0]:
   check(bounds.has_point(app.camera.unproject_position(Vector3(x,y,-21))),orientation+" full environment elevation fits")
func check(value:bool,label:String) -> void:
 if not value:failures.append(label)
 else:report.checks.append(label)
func rendered() -> bool:return DisplayServer.get_name()!="headless"
func frames(count:int) -> void:
 for i in count:await process_frame
func action(name:String) -> void:
 var event:=InputEventAction.new();event.action=name;event.pressed=true;Input.parse_input_event(event);await frames(2)
 event=InputEventAction.new();event.action=name;event.pressed=false;Input.parse_input_event(event);await frames(3)
func press(button:Control) -> void:
 button.grab_focus();await action("ui_accept");await frames(5)
func capture(label:String) -> void:
 if not rendered():return
 await frames(4);await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(destination.path_join(label+".png"))==OK,"capture "+label)
func contact() -> void:
 app.hide();app.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
 root.size=Vector2i(1080,1440);root.content_scale_size=root.size
 var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
 for i in 9:
  var picture:=TextureRect.new();picture.position=Vector2((i%3)*360+8,(i/3)*480+32);picture.size=Vector2(344,440)
  picture.texture=ImageTexture.create_from_image(stage_images[i]);picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;bg.add_child(picture)
  var label:=Label.new();label.position=Vector2((i%3)*360+12,(i/3)*480+6);label.text=app.manifest.stages[i].name;label.add_theme_font_size_override("font_size",18);bg.add_child(label)
 await capture("contact")

extends SceneTree
## Real inspector controls, native resources and rendered evidence; no League integration.
const Preview=preload("res://src/presentation/house_theme_preview.tscn")
const Lane=preload("res://src/simulation/lane_spec.gd")
var app:Control
var destination:=""
var failures:Array[String]=[]
var stage_images:Array[Image]=[]
var report:Dictionary={"stages":[],"checks":[]}
func _initialize():call_deferred("run")
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 root.size=Vector2i(720,1280);root.content_scale_size=root.size
 app=Preview.instantiate();root.add_child(app);await frames(12)
 var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/leagues/house.json"))
 check(app.manifest.stages.size()==9,"eight Divisions plus Championship")
 check(app.manifest.assets.size()==30,"thirty unique manifest bindings")
 for id in app.manifest.assets:check(ResourceLoader.exists(app.manifest.assets[id]),"resource exists: "+id)
 var regions:={}
 for i in 9:
  var row:Dictionary=app.manifest.stages[i]
  check(app.stage_index==i,"Next selects stage %d"%i)
  check(app.room.asset_id==row.environment_id and app.room.signage.asset_id==row.signage_id,"scene and sign IDs bind")
  check(app.room.signage.championship==(i==8),"Championship sign identity")
  check(app.room.get_node("DivisionTitle").text==("CHAMPIONSHIP" if i==8 else "DIVISION %02d"%(i+1)),"native sign text")
  if i<8:check(row.name==spec.divisions[i].name,"Division name matches League")
  check(not regions.has(str(app.room.backdrop.region)),"distinct architectural region")
  regions[str(app.room.backdrop.region)]=true
  check(app.room.find_children("*","CollisionObject3D",true,false).is_empty(),"environment is cosmetic")
  await capture("division_%02d"%(i+1) if i<8 else "championship")
  if rendered():stage_images.append(app.viewport.get_texture().get_image())
  report.stages.append({"id":row.environment_id,"sign":app.room.get_node("DivisionTitle").text,"region":str(app.room.backdrop.region)})
  if i<8:await press(app.next)
 await press(app.previous);check(app.stage_index==7,"Previous navigation")
 await press(app.next);check(app.stage_index==8,"Championship navigation")
 await press(app.next);check(app.stage_index==0,"stage wrap")
 await press(app.previous);check(app.stage_index==8,"reverse stage wrap")
 for control in [app.previous,app.next,app.lane_choice,app.overview,app.reduced,app.music_button,app.volume]:
  check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(control.get_global_rect()),"portrait control fits: "+control.get_class())
 var finish_images:Array[Image]=[]
 var before:Transform3D=app.world.get_node("Pin1").transform
 await press(app.overview)
 for i in 2:
  if i==1:
   app.lane_choice.grab_focus();await action("ui_accept");await action("ui_down");await action("ui_accept");await frames(8)
  check(app.lane_index==i,"lane selector native input")
  var material:ShaderMaterial=app.floor_mesh.material_override
  check(material.get_shader_parameter("dry_backend")==bool(i),"correct lane material")
  check(is_equal_approx(float(material.get_shader_parameter("oil_end_f")),Lane.OIL_END_F),"oil boundary matches LaneSpec")
  check(is_equal_approx(float(material.get_shader_parameter("deck_start_f")),Lane.DECK_ZONE_F),"deck boundary matches LaneSpec")
  await capture("house_oil" if i==0 else "dry_backend")
  if rendered():finish_images.append(app.viewport.get_texture().get_image())
 if rendered():
  var original:=finish_images[0];var changed:=finish_images[1]
  var oil_difference:=0.0;var dry_difference:=0.0;var count:=0
  for y in range(original.get_height()/8,original.get_height()*3/8):
   for x in range(original.get_width()*2/5,original.get_width()*3/5):
    var a:=original.get_pixel(x,y);var b:=changed.get_pixel(x,y)
    dry_difference+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
    var oil_y:=original.get_height()-1-y
    a=original.get_pixel(x,oil_y);b=changed.get_pixel(x,oil_y)
    oil_difference+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b);count+=1
  report.lane_pixel_difference={"backend_mean_rgb":dry_difference/count,"oil_mean_rgb":oil_difference/count}
  check(dry_difference/count>.04,"dry backend is visibly distinct in native pixels")
  check(oil_difference/count<.001,"condition switch preserves oiled pixels")
 check(before==app.world.get_node("Pin1").transform,"lane switch preserves rack geometry")
 await press(app.reduced);check(app.reduced.button_pressed,"reduced control")
 check(not "TIME" in app.floor_mesh.material_override.shader.code,"lane atmosphere is static")
 await capture("reduced")
 await press(app.overview)
 root.size=Vector2i(1280,720);root.content_scale_size=root.size;await frames(12)
 await capture("landscape")
 for control in [app.previous,app.next,app.lane_choice,app.overview,app.reduced,app.music_button,app.volume]:
  check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(control.get_global_rect()),"landscape control fits: "+control.get_class())
 var stream:AudioStreamWAV=app.music.stream
 check(stream.stereo and stream.mix_rate==22050,"stereo 22050 Hz original music")
 check(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"music imports as a forward loop")
 check(absf(stream.get_length()-42.666667)<.001,"sixteen bars at 90 BPM")
 await press(app.music_button);check(app.music.playing,"native music control starts player")
 app.volume.grab_focus();await action("ui_home");check(app.volume.value==0 and app.music.volume_db<=-80,"native volume mute")
 await action("ui_end");check(app.volume.value==1 and app.music.volume_db>-80,"native volume restore")
 app.music.seek(stream.get_length()-.08)
 var until:=Time.get_ticks_msec()+350
 while Time.get_ticks_msec()<until:await process_frame
 check(app.music.playing and app.music.get_playback_position()<1.0,"music wraps at loop end")
 report.music={"length":stream.get_length(),"loop":stream.loop_mode,"position_after_wrap":app.music.get_playback_position(),"driver":AudioServer.get_driver_name()}
 await press(app.music_button);check(not app.music.playing,"native music control stops player")
 if rendered():await contact()
 report.failures=failures
 var file:=FileAccess.open(destination.path_join("report.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "));file.close()
 for failure in failures:printerr("FAIL: ",failure)
 if failures.is_empty():print("ROGUEWOOD_HOUSE_THEME_OK stages=9 assets=30 lanes=2 music=loop")
 app.music.stream=null;stream=null
 app.queue_free();app=null;await frames(4)
 # Let the audio thread release its last playback reference before fast headless exit.
 var audio_cleanup:=Time.get_ticks_msec()+100
 while Time.get_ticks_msec()<audio_cleanup:await process_frame
 quit(0 if failures.is_empty() else 1)
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
  var image:=TextureRect.new();image.position=Vector2((i%3)*360+8,(i/3)*480+32);image.size=Vector2(344,440)
  image.texture=ImageTexture.create_from_image(stage_images[i]);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;bg.add_child(image)
  var label:=Label.new();label.position=Vector2((i%3)*360+12,(i/3)*480+6);label.text=app.manifest.stages[i].name;label.add_theme_font_size_override("font_size",18);bg.add_child(label)
 await capture("contact")

extends SceneTree
const Preview=preload("res://src/presentation/neon_theme_preview.tscn")
const Lane=preload("res://src/simulation/lane_spec.gd")
var app:Control
var destination:=""
var failures:Array[String]=[]
var report:Dictionary={"checks":[]}
func _initialize():call_deferred("run")
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 root.size=Vector2i(780,1688);root.content_scale_size=root.size
 app=Preview.instantiate();root.add_child(app);await frames(12)
 for id in app.manifest.assets:check(ResourceLoader.exists(app.manifest.assets[id]),"resource "+id)
 check(app.manifest.assets.size()==43,"43 theme bindings")
 var pins:={}
 for i in range(1,11):pins[i]=app.world.get_node("Pin%d"%i).transform
 await select(app.view_choice,1);check(app.view_index==1,"native lane view")
 var images:Array[Image]=[]
 for i in 3:
  await select(app.lane_choice,i);check(app.lane_index==i,"native lane selection")
  var row:Dictionary=app.manifest.lanes[i]
  var material:ShaderMaterial=app.world.get_node("LaneSurface").material_override
  check(material.resource_path==app.manifest.assets[row.visual_id],"exact lane material")
  check(is_equal_approx(material.get_shader_parameter("oil_end_f"),Lane.oil_end(row.condition_id,.2)),"right oil boundary matches physics")
  if i>0:check(is_equal_approx(material.get_shader_parameter("left_oil_end_f"),Lane.oil_end(row.condition_id,-.2)),"left oil boundary matches physics")
  check(is_equal_approx(material.get_shader_parameter("deck_start_f"),Lane.DECK_ZONE_F),"deck boundary matches physics")
  check(not "TIME" in material.shader.code,"static lane finish")
  await capture(["house_oil","long_oil","two_tone"][i])
  if rendered():images.append(app.viewport.get_texture().get_image())
 if rendered():
  var left:=difference(images[1],images[2],-.40,-.12,10.8,11.8)
  var right:=difference(images[1],images[2],.12,.40,10.8,11.8)
  var before:=difference(images[1],images[2],-.40,-.12,9.8,10.1)
  var long_end:=difference(images[1],images[2],.12,.40,12.6,13.3)
  check(left>.015,"Two-Tone dry left differs in grayscale")
  check(right<.0001,"Two-Tone wet right stays identical before 40 ft")
  check(before<.0001,"Two-Tone upstream oil stays identical")
  check(long_end>.015,"Long Oil remains visibly wet beyond 40 ft")
  report.grayscale_difference={"left":left,"right":right,"before":before,"long_oil":long_end}
 await press(app.reduced);check(app.reduced.button_pressed,"native reduction toggle")
 await capture("lane_reduced")
 if rendered():check(images[2].get_data()==app.viewport.get_texture().get_image().get_data(),"reduction preserves lane information")
 for i in pins:check(pins[i]==app.world.get_node("Pin%d"%i).transform,"lane material preserves rack geometry")
 await select(app.view_choice,2);check(app.view_index==2,"native kit view")
 app.flank.set_process(false);app.flank.phase=0;app.flank.queue_redraw()
 var frame_manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/neon/manifest.json"))
 for id in frame_manifest.frames:
  var row:Dictionary=frame_manifest.frames[id]
  var frame:StyleBoxTexture=load(row.path)
  check(frame.texture.get_size()==Vector2(64,64),"64px frame source")
  check(frame.texture_margin_left==row.slice_px,"nine-slice inset")
  check(frame.axis_stretch_horizontal==StyleBoxTexture.AXIS_STRETCH_MODE_TILE,"horizontal frame edges tile")
  check(frame.content_margin_left==row.content_inset_px,"frame text inset")
 var texture:Texture2D=app.kit_cells[-1].texture
 check(texture==load("res://assets/clubhouse/trophy.neon.png"),"exact trophy filename binding")
 if rendered():
  var trophy_image:=texture.get_image()
  var transparent_edges:=true
  for x in trophy_image.get_width():
   transparent_edges=transparent_edges and trophy_image.get_pixel(x,0).a<.01 and trophy_image.get_pixel(x,trophy_image.get_height()-1).a<.01
  check(transparent_edges,"trophy crown/base transparency margin")
 await capture("kit_reduced")
 var reduced_a:Image
 if rendered():reduced_a=root.get_texture().get_image()
 app.flank.phase=PI/2;app.flank.queue_redraw();await frames(8)
 await capture("kit_reduced_later")
 if rendered():check(reduced_a.get_data()==root.get_texture().get_image().get_data(),"reduced backdrop ignores phase")
 await press(app.reduced);check(not app.flank.reduced,"normal backdrop restored")
 app.flank.phase=0;app.flank.queue_redraw();await capture("kit_normal")
 var normal:Image
 if rendered():normal=root.get_texture().get_image()
 app.flank.phase=PI/2;app.flank.queue_redraw();await capture("kit_drift")
 if rendered():
  var drifted:=root.get_texture().get_image()
  check(normal.get_data()!=drifted.get_data(),"normal backdrop drifts")
  var corridor:=Rect2i(int(root.size.x*.25),int(app.kit.global_position.y),int(root.size.x*.5),int(app.kit.size.y))
  check(normal.get_region(corridor).get_data()==drifted.get_region(corridor).get_data(),"backdrop drift leaves central corridor unchanged")
 fit("portrait")
 root.size=Vector2i(1688,780);root.content_scale_size=root.size;await frames(12)
 await capture("kit_landscape");fit("landscape")
 await select(app.view_choice,1);await capture("lane_landscape")
 await select(app.view_choice,0);check(app.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"room camera restores after lane inspection")
 var stream:AudioStreamWAV=app.music.stream
 check(stream.stereo and stream.mix_rate==22050,"stereo 22050 Hz music")
 check(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"forward music loop")
 check(absf(stream.get_length()-240.0/112*16)<.001,"sixteen bars at 112 BPM")
 check(app.manifest.music.peak<=.65 and app.manifest.music.seam_delta<.01,"bounded original PCM and seam")
 await press(app.music_button);check(app.music.playing,"native music starts")
 app.volume.grab_focus();await action("ui_home");check(app.volume.value==0 and app.music.volume_db<=-80,"native volume mute")
 await action("ui_end");check(app.volume.value==1 and app.music.volume_db>-80,"native volume restores")
 app.music.seek(stream.get_length()-.08)
 var until:=Time.get_ticks_msec()+350
 while Time.get_ticks_msec()<until:await process_frame
 check(app.music.playing and app.music.get_playback_position()<1,"actual audio loop wraps")
 report.music={"length":stream.get_length(),"driver":AudioServer.get_driver_name(),"after_wrap":app.music.get_playback_position()}
 await press(app.music_button);check(not app.music.playing,"native music stops")
 app.music.stream=null;stream=null
 report.failures=failures
 var file:=FileAccess.open(destination.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 for failure in failures:printerr("FAIL: ",failure)
 if failures.is_empty():print("ROGUEWOOD_NEON_THEME_OK lanes=3 frames=5 music=loop trophy=neon")
 app.queue_free();app=null;await frames(4)
 until=Time.get_ticks_msec()+100
 while Time.get_ticks_msec()<until:await process_frame
 quit(0 if failures.is_empty() else 1)
func difference(a:Image,b:Image,x0:float,x1:float,f0:float,f1:float) -> float:
 var start:Vector2=app.camera.unproject_position(Lane.world(x0,f1,0))
 var end:Vector2=app.camera.unproject_position(Lane.world(x1,f0,0))
 var delta:=0.0;var count:=0
 for y in range(int(start.y),int(end.y)):
  for x in range(int(start.x),int(end.x)):
   if x<0 or y<0 or x>=a.get_width() or y>=a.get_height():continue
   var ca:=a.get_pixel(x,y);var cb:=b.get_pixel(x,y)
   delta+=absf((ca.r-cb.r)*.2126+(ca.g-cb.g)*.7152+(ca.b-cb.b)*.0722);count+=1
 check(count>20,"material comparison has visible samples")
 return delta/maxi(1,count)
func fit(orientation:String) -> void:
 for control in [app.view_choice,app.lane_choice,app.music_button,app.volume]+app.kit_cells:
  check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(control.get_global_rect()),orientation+" control fits "+control.name)
func check(value:bool,label:String) -> void:
 if value:report.checks.append(label)
 else:failures.append(label)
func rendered() -> bool:return DisplayServer.get_name()!="headless"
func frames(count:int) -> void:
 for i in count:await process_frame
func action(name:String) -> void:
 var event:=InputEventAction.new();event.action=name;event.pressed=true;Input.parse_input_event(event);await frames(2)
 event=InputEventAction.new();event.action=name;event.pressed=false;Input.parse_input_event(event);await frames(3)
func press(button:Control) -> void:
 button.grab_focus();await action("ui_accept");await frames(5)
func select(choice:OptionButton,index:int) -> void:
 var delta:=index-choice.selected
 choice.grab_focus();await action("ui_accept")
 for i in absi(delta):await action("ui_down" if delta>0 else "ui_up")
 await action("ui_accept");await frames(8)
 print("NEON_SELECT wanted=%d actual=%d"%[index,choice.selected])
func capture(label:String) -> void:
 if not rendered():return
 await frames(4);await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(destination.path_join(label+".png"))==OK,"capture "+label)

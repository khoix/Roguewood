extends SceneTree
const Preview=preload("res://src/presentation/ui_a1_preview.tscn")
var destination := ""
var failures:Array[String]=[]
var app:Control
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
 if not ok:failures.append(message);printerr("FAIL: "+message)
func frames() -> void:
 for i in 12:await process_frame
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 app=Preview.instantiate();root.add_child(app)
 for dimensions in [Vector2i(720,1280),Vector2i(1280,720)]:
  root.size=dimensions;root.content_scale_size=dimensions;await frames()
  for study in [false,true]:
   if app.studies!=study:
    app.toggle.grab_focus()
    var event:=InputEventAction.new();event.action="ui_accept";event.pressed=true;Input.parse_input_event(event);await process_frame
    event=InputEventAction.new();event.action="ui_accept";event.pressed=false;Input.parse_input_event(event)
   await frames()
   check(app.studies==study,"native button changes study mode")
   check(app.cards.size()==6 and app.art_windows.size()==5,"five faces plus back")
   var screen:=Rect2(Vector2.ZERO,Vector2(dimensions))
   for card in app.cards:
    check(screen.encloses(card.get_global_rect()),"card fits viewport")
   for i in app.cards.size():
    for j in range(i+1,app.cards.size()):check(not app.cards[i].get_global_rect().intersects(app.cards[j].get_global_rect()),"cards do not overlap")
   for label in app.labels:
    var font:Font=label.get_theme_font("font");var pixels:int=label.get_theme_font_size("font_size")
    for line in label.text.split("\n"):
     check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x<=label.size.x,"text width: "+line)
    check(label.get_minimum_size().y<=label.size.y,"text height: "+label.text)
    check(screen.encloses(label.get_global_rect()),"label fits viewport")
    check(pixels>=14,"native typography minimum")
   for art in app.art_windows:
    check(art.get_parent().get_global_rect().encloses(art.get_global_rect()),"art stays inside face")
    check(art.texture!=null,"existing item illustration loaded")
    check(art.size.x*art.size.y/(art.get_parent().size.x*art.get_parent().size.y)>.5,"art window occupies majority of face")
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    var name:String=("portrait" if dimensions.x<dimensions.y else "landscape")+("_studies" if study else "_cards")
    check(root.get_texture().get_image().save_png(destination.path_join(name+".png"))==OK,"capture "+name)
 await compositions()
 for symbol in ["value","mult","money"]:check(load("res://assets/ui/cards/"+symbol+".svg")!=null,"score symbol "+symbol)
 if "--inject-failure" in OS.get_cmdline_user_args():check(false,"injected failure")
 var file:=FileAccess.open(destination.path_join("report.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"failures":failures,"sizes":["720x1280","1280x720"],"minimum_font_px":14,"art_fraction":180.0*181/210/300},"  "))
 if failures.is_empty():print("ROGUEWOOD_UI_A1_OK")
 quit(0 if failures.is_empty() else 1)

func compositions() -> void:
 app.queue_free();await process_frame
 app=load("res://src/presentation/ui_a1_composition.tscn").instantiate();root.add_child(app)
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/house/manifest.json"))
 for id in manifest.frames:
  var entry:Dictionary=manifest.frames[id]
  var style:StyleBoxTexture=load(entry.path)
  check(style.texture.get_size()==Vector2(64,64),id+" master size")
  for side in 4:
   check(style.get_texture_margin(side)==entry.slice_px,id+" fixed corners")
   check(style.get_content_margin(side)==entry.content_inset_px,id+" safe content inset")
  check(style.axis_stretch_horizontal==StyleBoxTexture.AXIS_STRETCH_MODE_TILE,id+" tiles horizontally")
  check(style.axis_stretch_vertical==StyleBoxTexture.AXIS_STRETCH_MODE_TILE,id+" tiles vertically")
 var corner_samples:Dictionary={}
 var font:Font=load(manifest.font)
 for code in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789$":check(font.has_char(code.unicode_at(0)),"font covers "+code)
 for dimensions in [Vector2i(720,1280),Vector2i(1280,720)]:
  root.size=dimensions;root.content_scale_size=dimensions;await frames()
  for page in 3:
   app.tabs[page].grab_focus()
   var event:=InputEventAction.new();event.action="ui_accept";event.pressed=true;Input.parse_input_event(event);await process_frame
   event=InputEventAction.new();event.action="ui_accept";event.pressed=false;Input.parse_input_event(event);await frames()
   check(app.page==page,"native composition tab")
   var screen:=Rect2(Vector2(16,16),Vector2(dimensions)-Vector2(32,32))
   for control in app.panels+app.cards+app.actions+app.tabs:
    check(screen.encloses(control.get_global_rect()),"composition stays in safe area: "+control.get_class())
   for button in app.actions+app.tabs:check(button.size.y>=48,"button touch target")
   for label in app.labels+app.factory.labels:
    var face:Font=label.get_theme_font("font");var pixels:int=label.get_theme_font_size("font_size")
    for line in label.text.split("\n"):
     check(face.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x<=label.size.x,"composition text width: "+line)
    check(label.get_minimum_size().y<=label.size.y,"composition text height: "+label.text)
    check(screen.encloses(label.get_global_rect()),"composition label stays visible: "+label.text)
   for art in app.factory.art_windows:check(art.get_parent().get_global_rect().encloses(art.get_global_rect()),"composition card art contained")
   if page==0:
    check(not app.lane_camera.is_position_behind(app.aim_ball.global_position),"ball in front of camera")
    var ball_screen:Vector2=app.lane_camera.unproject_position(app.aim_ball.global_position)
    check(Rect2(Vector2(8,8),Vector2(app.viewport.size)-Vector2(16,16)).has_point(ball_screen),"ball visible with safe margin")
    check(app.viewport.size.x>=190 and app.viewport.size.y>=200,"lane render retains resolution")
    for card in app.cards:check(not card.get_global_rect().intersects(app.lane_view.get_global_rect()),"hand leaves aiming area clear")
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    var capture_image:Image=root.get_texture().get_image()
    for panel in app.panels:
     var kind:String=panel.get_meta("kit_kind")
     var corner:Image=capture_image.get_region(Rect2i(Vector2i(panel.global_position),Vector2i(12,12)))
     if corner_samples.has(kind):check(corner.get_data()==corner_samples[kind],"rendered corners remain unscaled: "+kind)
     else:corner_samples[kind]=corner.get_data()
    var name:String=("portrait" if dimensions.x<dimensions.y else "landscape")+"_"+["throw","shop","kit"][page]
    check(root.get_texture().get_image().save_png(destination.path_join(name+".png"))==OK,"capture "+name)

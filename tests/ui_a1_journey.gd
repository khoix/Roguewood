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
    var name:=("portrait" if dimensions.x<dimensions.y else "landscape")+("_studies" if study else "_cards")
    check(root.get_texture().get_image().save_png(destination.path_join(name+".png"))==OK,"capture "+name)
 for symbol in ["value","mult","money"]:check(load("res://assets/ui/cards/"+symbol+".svg")!=null,"score symbol "+symbol)
 if "--inject-failure" in OS.get_cmdline_user_args():check(false,"injected failure")
 var file:=FileAccess.open(destination.path_join("report.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"failures":failures,"sizes":["720x1280","1280x720"],"minimum_font_px":14,"art_fraction":180.0*181/210/300},"  "))
 if failures.is_empty():print("ROGUEWOOD_UI_A1_OK")
 quit(0 if failures.is_empty() else 1)

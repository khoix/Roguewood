extends "res://tests/ui_a1_journey.gd"
func compositions() -> void:
 await super.compositions()
 app.queue_free();await process_frame
 app=load("res://src/presentation/ui_a1_revision.tscn").instantiate();root.add_child(app)
 for dims in [Vector2i(720,1280),Vector2i(1280,720),Vector2i(1024,768)]:
  root.size=dims;root.content_scale_size=dims
  for option in 2:
   for reduced in [false,true]:
    for page in 2:
     app.option=option;app.reduced=reduced;app.page=page;app.rebuild()
     for n in 12:await process_frame
     var name:="%dx%d_%d_%s_%s"%[dims.x,dims.y,option,"still" if reduced else "motion","throw" if page==0 else "shop"]
     if DisplayServer.get_name()!="headless":
      await RenderingServer.frame_post_draw
      if root.get_texture().get_image().save_png(destination.path_join(name+".png"))!=OK:failures.append(name)
     if page==1 and dims.x>dims.y and app.cards.size()!=3:failures.append("three shop columns")
     if page==0:
      var expected:=2 if dims.x<dims.y else (0 if dims.x==1024 else 4)
      if app.cards.size()!=expected:failures.append("hand count: "+name)
     if page==0:
      var ball:Vector2=app.lane_camera.unproject_position(app.aim_ball.global_position)
      check(absf(ball.y/app.viewport.size.y-.667)<.015,"ball at two-thirds height")
      for card in app.cards:check(not card.get_global_rect().intersects(app.corridor),"hand clear of corridor")
      for z in [-12.5,-17.0]:
       for x in [-app.Lane.LANE_HALF_WIDTH,app.Lane.LANE_HALF_WIDTH]:
        var point:Vector2=app.lane_camera.unproject_position(Vector3(x,0,z))*app.lane_view.size/Vector2(app.viewport.size)+app.lane_view.global_position
        check(app.corridor.has_point(point),"projected playable lane stays inside reserved corridor")
     for label in app.labels:
      check(label.get_theme_font("font").get_string_size(label.text.split("\n")[0],HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x<=label.size.x,"revision text width: "+label.text)
     var phase:float=app.backdrop.phase
     await process_frame
     if reduced and app.backdrop.phase!=phase:failures.append("reduced backdrop moved")

 for sample in ["folded_hand","folded_details","left_handed"]:
  root.size=Vector2i(720,1280) if sample=="left_handed" else Vector2i(1024,768)
  root.content_scale_size=root.size;await frames()
  app.page=0;app.reduced=true;app.left_handed=sample=="left_handed";app.show_hand=false;app.show_details=false;app.rebuild();await frames()
  if sample!="left_handed":
   var button:Button=app.actions[1 if sample=="folded_hand" else 2]
   button.grab_focus()
   var event:=InputEventAction.new();event.action="ui_accept";event.pressed=true;Input.parse_input_event(event);await process_frame
   event=InputEventAction.new();event.action="ui_accept";event.pressed=false;Input.parse_input_event(event);await frames()
   check(app.show_hand if sample=="folded_hand" else app.show_details,"native fold toggle")
  for card in app.cards:check(not card.get_global_rect().intersects(app.corridor),"expanded hand clear of lane")
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   check(root.get_texture().get_image().save_png(destination.path_join(sample+".png"))==OK,"capture "+sample)

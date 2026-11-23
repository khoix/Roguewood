extends "res://tests/charm_c01_journey.gd"
## AV-FIX1: actual Binder preview, no Career/unlock fixtures.
var baseline_views: Array[Resource] = []
var before_art := false
func _run() -> void:
 baseline_views = preload("res://tools/spare_jar_capture_art.gd").prepare(before_art)
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
 root.size = PORTRAIT
 scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 await _wait_for(func(): return scene.screen == "menu" and scene.enter.has_focus(),"menu ready")
 await _focus_accept(scene.clubhouse.tab_buttons.binder)
 await _focus_accept(scene.clubhouse.filter_button("charm"))
 await _focus_accept(scene.clubhouse.entry_button("charm.spare_jar"))
 _check(scene.clubhouse.selected_item == "charm.spare_jar" and scene.clubhouse.binder_preview.visible,"real Spare Jar Binder preview")
 for landscape in [false,true]:
  root.size = Vector2i(1280,720) if landscape else PORTRAIT
  for i in 12: await process_frame
  if DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   _check(root.get_texture().get_image().save_png(artifact_dir.path_join("binder_"+("landscape" if landscape else "portrait")+".png")) == OK,"Binder capture")
 if failures.is_empty(): print("ROGUEWOOD_FIX1_BINDER_OK")
 quit(0 if failures.is_empty() else 1)

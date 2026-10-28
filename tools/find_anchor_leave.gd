extends SceneTree
## Read-only fixture search through real Jolt worlds; never used by production.
const Lane = preload("res://src/simulation/lane_spec.gd")
const World = preload("res://src/simulation/lane_world.gd")
const Physics = preload("res://tests/physics_test.gd")
const Profiles = preload("res://src/simulation/item_physics.gd")
var active := 0
var found := []
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	for x in [-0.2,-0.1,0.0,0.1,0.2]:
		for spin in [0.0,0.25,0.5]:
			while active >= 5: await physics_frame
			_shot(x,spin)
	while active > 0: await physics_frame
	print("ANCHOR_LEAVES ",found)
	quit()
func _shot(x: float, spin: float) -> void:
	active += 1
	var view := SubViewport.new()
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(view)
	var world := World.new()
	view.add_child(world)
	var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("slice").catalogue
	var pins := {}
	for i in range(1,11): pins[i] = "pin.anchor" if i == 8 else "pin.wood"
	world.setup(Lane.fresh_rack(),null,Profiles.profiles(catalogue,pins))
	var launch := Physics.launch_of({"start_x":x,"angle_deg":0,"power":0.7,"spin":spin},"anchor-search")
	world.commit(launch)
	for i in 2000:
		if world.state == "finished": break
		await physics_frame
	var standing: Array = world.report.knockdown_log.standing
	print("ANCHOR ",x," ",spin," ",standing)
	if standing == [8]: found.append([x,0,0.7,spin])
	view.queue_free()
	active -= 1

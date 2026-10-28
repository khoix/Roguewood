extends "res://tests/clubhouse_journey.gd"
## Runs all original J11 actions/assertions; adds real-art and viewport evidence.
const CLUB_IDS := ["trophy.house", "trophy.house_campaign", "ribbon.spare_hand", "ribbon.true_curve", "ribbon.mixed_rack", "plaque.surveyor", "plaque.custodian", "deco.club_sign", "deco.lane_trim", "deco.trophy_case"]

func _capture(label: String) -> void:
	var club = scene.clubhouse
	for id in CLUB_IDS:
		_check(club.Art.has_art(id), "final Clubhouse resource " + id)
	if club.current_tab == "binder":
		# Delivered art only: items whose catalogue artwork flag is set (coordinator scope fix for E18-C01's new Charms).
		var delivered := {}
		for item in scene.career_graph.catalogue.items:
			if item.completeness.artwork: delivered["Binder_" + item.id.replace(".", "_")] = true
		for card in club.binder_grid.get_children():
			if delivered.has(String(card.name)): _check(card.icon != null, "binder identity " + card.name)
			_check(card.text.contains("Locked") or card.text.contains("Available") or card.text.contains("Discovered") or card.text.contains("Mastered"), "state remains explicit without color")
		if label == "clubhouse_mastered":
			var art = club.binder_art.get_child(0)
			_check(art.material is ShaderMaterial and art.material.shader == load("res://assets/motion/foil.gdshader"), "Mastered uses E12 foil")
			_check(art.material.get_shader_parameter("tilt") == Vector2.ZERO, "foil is spatially static, including reduced motion")
	await super._capture(label)
	if label not in ["clubhouse_locked", "clubhouse_mastered", "clubhouse_discovered", "clubhouse_trophies", "clubhouse_goals"]: return
	for dimensions in [Vector2i(720,1280), Vector2i(1280,720)]:
		root.size = dimensions
		for i in 8: await process_frame
		for button in club.tab_buttons.values():
			_check(button.size.y >= 52 and button.get_global_rect().end.x <= club.size.x + 1, "tab target and horizontal bounds")
		if club.current_tab == "binder":
			_check(club.binder_detail.get_global_rect().end.x <= club.size.x + 1, "binder text fits viewport")
			for card in club.binder_grid.get_children():
				_check(card.get_global_rect().end.x <= club.size.x + 1, "binder card fits horizontally")
		await super._capture(label + "_" + str(dimensions.x))
		if club.current_tab == "trophies":
			var scroll: ScrollContainer = club.pages.trophies.get_parent()
			scroll.ensure_control_visible(club.trophy_grid.get_child(-1))
			for i in 4: await process_frame
			await super._capture(label + "_bottom_" + str(dimensions.x))
			scroll.scroll_vertical = 0
	root.size = PORTRAIT
	for i in 6: await process_frame

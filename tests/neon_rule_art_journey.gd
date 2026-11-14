extends "res://tests/neon_c13_journey.gd"
## Native art extension; retains ALL C13 mechanics/bank/layout checks.
## J22L02RULEART: coordinator bar-height prerequisite merged before registration.
func _capture(label:String) -> void:
 await super._capture(label)
 if label not in ["c13_narrow_lane","c13_champion"]:return
 var overlay:Control=lab.get_node("AimOverlay")
 _check(overlay.NeonArt==load("res://assets/leagues/neon/rule_overlay.gd"),"authored Neon rule painter bound")
 if label=="c13_narrow_lane":
  _check(is_equal_approx(lab.lane.gutter_edge(),Lane.LANE_HALF_WIDTH-2*Lane.BOARD_WIDTH),"authored rails use existing two-board boundary")
 else:
  _check(is_equal_approx(Lane.perfect_ring(lab.zone_scale()),.07) and is_equal_approx(Lane.sweet_ring(lab.zone_scale()),.11),"Strobe art uses exact narrowed ring thresholds")
 # Hide tuning controls for art captures, then restore C13's assist via native input.
 await _focus_accept(scene.options)
 await _focus_accept(lab.settings_panel.assist)
 await _focus_accept(lab.settings_panel.close)
 _check(not lab.settings_panel.assist.button_pressed,"art capture hides assist controls")
 # C13 starts in reduced motion; exercise both modes through the real menu.
 await super._capture(label+"_art_reduced")
 await _focus_accept(scene.options)
 await _focus_accept(lab.settings_panel.reduced_motion)
 await _focus_accept(lab.settings_panel.close)
 _check(not lab.settings.reduced_motion,"normal mode native toggle")
 await super._capture(label+"_art_normal")
 root.size=Vector2i(800,450)
 for i in 12:await process_frame
 await super._capture(label+"_art_landscape")
 root.size=PORTRAIT
 for i in 12:await process_frame
 await _focus_accept(scene.options)
 await _focus_accept(lab.settings_panel.reduced_motion)
 await _focus_accept(lab.settings_panel.assist)
 await _focus_accept(lab.settings_panel.close)
 _check(lab.settings.reduced_motion and lab.settings_panel.assist.button_pressed,"reduction and assist restored for inherited C13")

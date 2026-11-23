extends "res://tests/neon_n4_art_journey.gd"
## Reduced timing deliberately cannot earn accuracy. Preserve the real normal
## launch, then switch presentation reduction after commit; no grade is forged.
func _trade_in() -> void:
 lab.settings.reduced_motion = true
 await super._trade_in()
func _timed_throw(shot: Array, spin: float, target: float) -> void:
 lab.settings.reduced_motion = false
 await super._timed_throw(shot,spin,target)
func _focus_accept(control: Control) -> void:
 var is_comet_throw: bool = is_instance_valid(lab) and control == lab.assist_panel.throw_button and lab.armed_ball_id() == "ball.comet"
 await super._focus_accept(control)
 if is_comet_throw:
  _check(lab.state == "rolling","normal timed launch committed before presentation reduction")
  lab.settings.reduced_motion = true

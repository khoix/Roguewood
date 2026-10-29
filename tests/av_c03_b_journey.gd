extends "res://tests/av_c03_a_journey.gd"
## The second three-item AV session reuses native purchase/binder/control checks.
var timed_grades := false
var partial_captured := false
func _batch() -> String:return "AV-C03-B"
func _play_batch() -> void:
 if lab.settings.reduced_motion:
  await _focus_accept(scene.options)
  await _focus_accept(lab.settings_panel.reduced_motion)
  await _focus_accept(lab.settings_panel.close)
 timed_grades=true
 var first:=await _frame([C03_SPLIT,C03_CONVERT],"two timed grades, full back row, behind")
 _check(first.result.category=="spare" and first.result.facts.accurate==2,"two real sweet/perfect releases")
 var sweet:Array=frame_cues.filter(func(e):return e.id=="charm.sweet_spot")
 _check(sweet.size()==1 and sweet[0].details.count==2 and sweet[0].details.amount==6 and sweet[0].details.grades.all(func(g):return g in ["sweet","perfect"]),"Sweet Spot shows both actual counted grades")
 _back_count(first)
 _check(frame_cues.any(func(e):return e.id=="charm.underdog" and e.details.match_score==0 and e.details.match_target==500 and e.details.behind),"native behind comparison 0 vs half of 500")
 await _controls(first)
 timed_grades=false
 await _next_frame()
 # Explicit pre-frame boundary fixture, not a report or resolver-result mutation.
 lab.division.active.match_score=lab.division.target()/2
 print("AV-C03-B fixture: existing match score exactly half its real target: ",lab.division.match_score," / ",lab.division.target())
 var second:=await _frame([STRIKE],"exactly half target, steady release")
 _check(not second.result.facts.behind and second.result.facts.accurate==0,"native half boundary and clean grade")
 _check(not _ids().has("charm.underdog") and not _ids().has("charm.sweet_spot"),"half target and clean grade stay quiet")
 _back_count(second)
 await _next_frame()
 lab.division.active.match_score=lab.division.target()/2+1
 print("AV-C03-B fixture: prior score above half target")
 var partial:=await _frame([C03_SPLIT,GUTTER],"above half, two back pins")
 _back_count(partial)
 _check(_ids()==["charm.back_row"] and frame_cues[0].details.positions==[7,9],"partial native back row highlights only 7 and 9")
 await _next_frame()
 await _frame([GUTTER,GUTTER],"above half, no grades, no back pins")
 _check(_ids().is_empty(),"all three quiet above half on a double gutter")

func _throw(shot:Array,spin:float=0.0,set_spin:bool=true) -> Dictionary:
 if not timed_grades:return await super._throw(shot,spin,set_spin)
 await _aim()
 var panel:Control=lab.assist_panel
 await _slide(panel.position_slider,shot[0])
 await _slide(panel.aim_slider,shot[1])
 await _slide(panel.power_slider,shot[2])
 if set_spin:await _slide(panel.spin_slider,spin)
 await _slide(panel.target_slider,shot[0])
 var count:int=lab.history.size()
 await _wait_for(func():return lab.ring_radius>=0.12 and lab.ring_radius<=0.135,"native contracting ring sweet window",300)
 await _focus_accept(panel.throw_button)
 _check(lab.state=="rolling","timed native Throw commits")
 await _wait_for(func():return lab.history.size()==count+1,"timed physical roll settles",ROLL_FRAMES)
 print("AV-C03-B actual grade: ",lab.history[-1].roll_result.accuracy," radius ",lab.history[-1].launch.ring_radius)
 return lab.history[-1]

func _back_count(scored:Dictionary) -> void:
 var positions:=[]
 for p in [7,8,9,10]:
  if scored.frame.rolls.any(func(r):return p in r.fallen_positions):positions.append(p)
 var cues:Array=frame_cues.filter(func(e):return e.id=="charm.back_row")
 _check(cues.size()==1 and cues[0].details.positions==positions and cues[0].details.count==positions.size(),"Back Row uses actual distinct slots and count")

func _observe_row(step:Dictionary,index:int,skipped:bool) -> void:
 super._observe_row(step,index,skipped)
 if skipped:return
 var abilities:Node=lab.motion.abilities
 if abilities.glyph.style!=null and abilities.glyph.style.item_id=="charm.back_row" and step.text.contains("Back Row"):
  _check(abilities.counted_rack_positions()==abilities.glyph.details.positions,"native rack highlights exactly the counted back-row pins")

  if abilities.glyph.details.positions==[7,9] and not partial_captured:
   partial_captured=true
   await _capture("back_row_partial")

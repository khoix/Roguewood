extends "res://tests/ability_journey.gd"
## Three isolated, real-input stages. Inventory fixtures are explicit; reports,
## resolver events, banks, payouts and seeded breaks always come from the game.
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Assets = preload("res://src/presentation/item_assets.gd")
var stage := 1
var frame_cues: Array = []
var checks: Array = []

func _run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
  if arg.begins_with("--stage="): stage = int(arg.trim_prefix("--stage="))
 root.size = Vector2i(720,1280)
 scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
 scene.throw_settings = {"practice":true,"score_speed":1}
 root.add_child(scene)
 await process_frame
 await _focus_accept(scene.enter)
 await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim","V08 ready")
 lab = scene.lab
 lab.trial_log_path = ""
 await _toggle_assist()
 wanted = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects/batches.json"))["E20-V08"].map(func(row): return row[0])
 var expected: Array
 if stage == 1:
  expected = ["charm.pin_counter","charm.hot_streak","charm.last_stand","charm.tip_jar","charm.plumb_line"]
  _seat(expected)
  var first := await _frame([STRIKE],"first strike")
  _check(_ids().has("charm.pin_counter") and _ids().has("charm.plumb_line") and not _ids().has("charm.hot_streak") and not _ids().has("charm.last_stand") and not _ids().has("charm.tip_jar"),"first strike cues only its actual bonuses")
  _check(first.income == 0,"strike pays no Tip Jar")
  await _next_frame()
  await _frame([STRIKE],"second strike")
  _check(_ids().has("charm.hot_streak"),"second consecutive strike cues Hot Streak")
  var hot: Dictionary = frame_cues.filter(func(e): return e.id=="charm.hot_streak")[0]
  _check(hot.details.streak==2,"flame tally shows actual streak two")
  await _next_frame()
  var spare := await _frame([LEAVE,[0.0,0.0,0.6]],"spare")
  _check(spare.income==1 and _ids().count("charm.tip_jar")==1 and not _ids().has("charm.hot_streak") and lab.run.strike_streak==0,"one after-bank Tip Jar; streak resets")
  _check(frame_cues.filter(func(e): return e.id=="charm.tip_jar")[0].event=="after_bank","Tip Jar cue follows bank")
  await _next_frame()
  var open := await _frame([LEAVE,GUTTER],"standing pins")
  _check(open.result.category=="open" and _ids().has("charm.last_stand") and not _ids().has("charm.tip_jar"),"standing bonus without spare income")
  await _controls(open)
 elif stage == 2:
  expected = ["charm.banana_ball"]
  _seat(["charm.banana_ball","charm.plumb_line"])
  var curved := await _frame([[-0.15,0.0,0.7]],"curved strike",0.25)
  _check(curved.result.category=="strike" and _ids().count("charm.banana_ball")==1 and not _ids().has("charm.plumb_line"),"real curved strike triggers Banana, not Plumb")
  _check(curved.frame.rolls[0].curved and curved.banked==840,"native calibrated curve banks 840")
  await _controls(curved)
  await _next_frame()
  await _frame([GUTTER,GUTTER],"curved non-strike",0.25)
  _check(not _ids().has("charm.banana_ball") and not _ids().has("charm.plumb_line"),"curved open stays quiet")
  await _next_frame()
  await _frame([STRIKE],"straight strike")
  _check(not _ids().has("charm.banana_ball") and _ids().has("charm.plumb_line"),"straight strike cues only Plumb")
 else:
  expected = ["charm.glass_cutter","pin.glass"]
  _seat(["charm.glass_cutter"])
  _glass_rack()
  _check(await _arm("ball.echo"),"native Echo for deferred-break deduplication")
  var first := await _frame([STRIKE],"Glass with Echo")
  _check(first.result.retriggers==1,"real Echo retrigger")
  _check_breaks(first)
  await _capture("glass_first_break")
  await _next_frame()
  _glass_rack()
  var second := await _frame([STRIKE],"two ordered Glass breaks")
  _check_breaks(second)
  _check(lab.run.transformed.size()>=2,"multiple confirmed breaks exercise explanation order")
  await _capture("glass_ordered_breaks")
  await _controls(second)
  await _next_frame()
  await _frame([GUTTER,GUTTER],"no Glass falls")
  _check(not _ids().has("charm.glass_cutter") and not _ids().has("pin.glass"),"standing Glass produces no Cutter or crack")
 for id in expected:
  _check(lab.motion.abilities.history.any(func(e): return e.id==id and not e.skipped and e.audio_played),"native activation and actual audio played: "+id)
  _check(captures.has(id),"native activation captured: "+id)
 _check(lab.motion.sound.max_active<=4 and lab.motion.abilities.world_glyphs.size()==4,"bounded audio and world glyph pools")
 var report := {"stage":stage,"checks":checks,"motion":metrics,"audio":{"played":lab.motion.sound.played,"suppressed":lab.motion.sound.suppressed,"max_active":lab.motion.sound.max_active},"events":lab.motion.abilities.history}
 var file := FileAccess.open(artifact_dir.path_join("metrics-stage%d.json"%stage),FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"\t"));file.close()
 if "--inject-failure" in OS.get_cmdline_user_args(): _check(false,"Injected V08 diagnostic failure")
 if failures.is_empty(): print("ROGUEWOOD_V08_OK" if stage==3 else "ROGUEWOOD_V08_STAGE%d_OK"%stage)
 for i in 8: await process_frame
 quit(0 if failures.is_empty() else 1)

func _seat(ids: Array) -> void:
 for id in ids: _check(lab.run.place(id,0,"charm:new").is_empty(),"fixture seats "+id)
 print("V08 stage %d inventory fixture: %s"%[stage,str(ids)])

func _glass_rack() -> void:
 for position in range(1,11): lab.run.rack[position]=Inventory._entry("pin.glass",0)
 print("V08 fixture: ten Glass; effects stream ",lab.run.effects_state)
 lab._new_roll(false)

func _next_frame() -> void:
 await _focus_accept(lab.next_rack)
 if lab.state=="shop": await _leave_shop()
 await _aim()

func _ids() -> Array:
 return frame_cues.filter(func(e): return not e.skipped).map(func(e): return e.id)

func _frame(shots: Array,label: String,spin: float=0.0) -> Dictionary:
 var loadout: Dictionary = lab.run.loadout()
 var context := {"match_frame":lab.match_frame,"strike_streak":lab.run.strike_streak}
 var stream: int = lab.run.effects_state
 var before: int = lab.history.size()
 var cue_start: int = lab.motion.abilities.history.size()
 for shot in shots: await _throw(shot,spin)
 var scored := await _scored()
 var built := Builder.build(loadout,lab.content.catalogue,lab.history.slice(before),{},context)
 var resolved := Rules.resolve(built.frame)
 _check(built.ok and resolved.score==scored.banked,"independent bank: "+label)
 var replay = Inventory.create(lab.content.catalogue,range(1,11).map(func(p): return loadout.pins[p]),[])
 replay.effects_state=stream
 replay.apply_frame(resolved,built.frame)
 _check(lab.run.effects_state==replay.effects_state and lab.run.transformed==replay.transformed,"independent break stream: "+label)
 frame_cues=lab.motion.abilities.history.slice(cue_start).filter(func(e): return e.id in wanted)
 for cue in frame_cues:
  if cue.id in ["charm.pin_counter","charm.last_stand","charm.glass_cutter"]:
   var source_events: Array = resolved.events.filter(func(e): return preload("res://src/presentation/ability_events.gd").owner(built.frame,e.get("source",""))==cue.id)
   _check(not source_events.is_empty() and cue.details.count==source_events[0].count,"glyph count comes from resolver: "+cue.id)
 checks.append({"label":label,"category":scored.result.category,"banked":scored.banked,"income":scored.income,"ids":_ids(),"breaks":lab.run.transformed.duplicate(true)})
 metrics.append(lab.motion.metrics())
 print("V08 ",label," bank=",scored.banked," cues=",_ids()," breaks=",lab.run.transformed)
 return scored

func _check_breaks(scored: Dictionary) -> void:
 var cracks: Array = frame_cues.filter(func(e): return e.id=="pin.glass" and not e.skipped)
 var expected: Array = lab.run.transformed.map(func(t): return t.position)
 _check(cracks.map(func(e): return e.details.position)==expected,"cracks follow confirmed break order, once despite Echo")
 for crack in cracks:
  _check(crack.event=="after_bank_break" and crack.details.step>=scored.result.events.size(),"crack comes after bank and chance rows")
  _check(scored.steps[crack.details.step].pin==crack.details.position,"cue matches the current explanation pin")
  var body: RigidBody3D=lab.lane.pins[crack.details.position]
  _check(body.get_meta("art_item_id")=="pin.wood","crack presents saved Wood identity")
 _check(cracks.size()<10,"unbroken Glass never emits a crack")

func _controls(scored: Dictionary) -> void:
 var invariant := JSON.stringify([lab.total_score,lab.run.to_dict(),scored.result])
 lab.score_panel.finished.disconnect(lab._on_scored)
 var fast_start: int=lab.motion.abilities.history.size()
 lab.score_panel.play(scored.steps,lab.frame_reports,scored.title,4)
 await _wait_for(func(): return not lab.score_panel.playing,"4x explanation completes",1800)
 var fast: Array=lab.motion.abilities.history.slice(fast_start)
 if stage==3:
  var fast_cracks: Array=fast.filter(func(e): return e.id=="pin.glass" and not e.skipped)
  _check(fast_cracks.map(func(e): return e.details.position)==lab.run.transformed.map(func(t): return t.position),"4x preserves confirmed crack order")
  await _capture("stage3_fast")
 _check(JSON.stringify([lab.total_score,lab.run.to_dict(),scored.result])==invariant,"4x never mutates bank, inventory or stream")
 root.size=Vector2i(1280,720)
 for i in 12: await process_frame
 await _capture("stage%d_landscape"%stage)
 _check(Rect2(Vector2.ZERO,lab.size).encloses(lab.score_panel.get_rect()),"score controls fit landscape")
 await _focus_accept(scene.options)
 await _focus_accept(lab.settings_panel.find_child("SoundAndEffects",true,false))
 var sound: Node=lab.motion.sound
 await _focus_accept(sound.mute_button)
 var played: int=sound.played
 sound.cue("v08_muted",Assets.slot(wanted[0],"sound"),3)
 _check(sound.muted and sound.played==played,"native mute suppresses audio")
 await _focus_accept(sound.mute_button)
 await _slide(sound.volume_slider,0)
 sound.cue("v08_zero",Assets.slot(wanted[0],"sound"),3)
 _check(sound.volume==0 and sound.played==played,"native zero volume suppresses audio")
 await _slide(sound.volume_slider,0.65)
 await _focus_accept(sound.effects_button)
 await process_frame
 _check(not lab.motion.abilities.glyph.enabled,"native effect toggle")
 await _focus_accept(sound.effects_button)
 await _focus_accept(sound.panel.get_child(0).get_child(sound.panel.get_child(0).get_child_count()-1))
 await _focus_accept(lab.settings_panel.reduced_motion)
 await _focus_accept(lab.settings_panel.reduced_flash)
 await _focus_accept(lab.settings_panel.close)
 root.size=Vector2i(720,1280)
 lab.score_panel.reduced_motion=true
 lab.score_panel.play(scored.steps,lab.frame_reports,scored.title,1)
 await _wait_for(func(): return lab.motion.abilities.glyph.style!=null and lab.motion.abilities.glyph.style.item_id in wanted and lab.motion.abilities.glyph.still and lab.motion.abilities.glyph.age<0.1,"static actual V08 replay",1800)
 await _capture("stage%d_reduced"%stage)
 played=sound.played
 await _focus_accept(lab.score_panel.skip_button)
 _check(not lab.score_panel.playing and sound.played==played,"native Skip is silent")
 _check(JSON.stringify([lab.total_score,lab.run.to_dict(),scored.result])==invariant,"presentation controls never mutate bank, inventory or stream")
 lab.score_panel.finished.connect(lab._on_scored)

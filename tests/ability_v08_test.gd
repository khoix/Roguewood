extends RefCounted
const Slice = preload("res://tests/slice_test.gd")
const Events = preload("res://src/presentation/ability_events.gd")
static func _cues(result: Dictionary) -> Array:
 var out: Array=[]
 for event in result.events: out.append_array(Events.project(result.frame,event))
 return out
static func _for(result: Dictionary,id: String) -> Array:
 return _cues(result).filter(func(c): return c.id==id)
static func run() -> Array[String]:
 var failures: Array[String]=[]
 var catalogue: Dictionary=preload("res://src/rules/content_set.gd").load_set("slice").catalogue
 var ids=["charm.pin_counter","charm.hot_streak","charm.last_stand","charm.tip_jar","charm.plumb_line"]
 var first:=Slice._score(catalogue,Slice._loadout({},ids),Slice._strike())
 var second:=Slice._score(catalogue,Slice._loadout({},ids),Slice._strike(),{"strike_streak":1})
 var spare:=Slice._score(catalogue,Slice._loadout({},ids),Slice._spare([1,2,3]))
 var open:=Slice._score(catalogue,Slice._loadout({},ids),Slice._open([1,2,3],[]))
 var empty:=Slice._score(catalogue,Slice._loadout({},ids),Slice._open([],[]))
 if _for(first,ids[0]).size()!=1 or _for(first,ids[0])[0].count!=10 or not _for(empty,ids[0]).is_empty(): failures.append("Pin Counter uses ten actual falls; zero stays quiet")
 if not _for(first,ids[1]).is_empty() or _for(second,ids[1]).size()!=1 or _for(second,ids[1])[0].streak!=2 or not _for(spare,ids[1]).is_empty(): failures.append("Hot Streak cues only active second-plus strike with real streak")
 if not _for(first,ids[2]).is_empty() or _for(open,ids[2])[0].count!=7: failures.append("Last Stand counts actual standing pins; clear stays quiet")
 if not _for(first,ids[3]).is_empty() or _for(spare,ids[3]).size()!=1 or _for(spare,ids[3])[0].phase!="after_bank" or _for(spare,ids[3])[0].amount!=1: failures.append("Tip Jar pays once after bank on spare only")
 var curve_ids=["charm.banana_ball","charm.plumb_line"]
 var curve:=Slice._score(catalogue,Slice._loadout({},curve_ids),Slice._strike("ball.house",.25))
 var curve_open:=Slice._score(catalogue,Slice._loadout({},curve_ids),[Slice._rep(1,[1],[1,2,3,4,5,6,7,8,9,10],"ball.house",.25),Slice._rep(2,[],[2,3,4,5,6,7,8,9,10])])
 var straight:=Slice._score(catalogue,Slice._loadout({},curve_ids),Slice._strike())
 if _for(curve,curve_ids[0]).size()!=1 or _for(curve,curve_ids[0])[0].amount!=1.5 or not _for(curve_open,curve_ids[0]).is_empty() or not _for(straight,curve_ids[0]).is_empty(): failures.append("Banana requires both curve and strike")
 if not _for(curve,curve_ids[1]).is_empty() or not _for(curve_open,curve_ids[1]).is_empty() or _for(straight,curve_ids[1]).size()!=1: failures.append("Plumb is silent if any roll curved")
 var glass:=Slice._score(catalogue,Slice._loadout({1:"pin.glass",2:"pin.glass"},["charm.glass_cutter"]),Slice._strike("ball.echo"))
 var before:=JSON.stringify(glass)
 var cutter:=_for(glass,"charm.glass_cutter")
 if cutter.size()!=1 or cutter[0].count!=2 or cutter[0].amount!=8: failures.append("Cutter counts two actual Glass falls once, independent of Echo")
 if not _for(glass,"pin.glass").is_empty(): failures.append("transform chance does not fabricate a crack; saved break rows own it")
 if JSON.stringify(glass)!=before: failures.append("projection mutated resolver input")
 return failures

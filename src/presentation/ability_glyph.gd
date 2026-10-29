extends Control
## A bounded 64px annotation next to the score header; never covers a log row.
var style: Resource
var age := 10.0
var still := false
var enabled := true
var identity: Texture2D
var details := {}
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(64,64)
	texture_filter = TEXTURE_FILTER_NEAREST
func show_cue(recipe: Resource, reduced: bool, texture: Texture2D, context: Dictionary = {}) -> void:
	style = recipe
	age = 0
	still = reduced
	identity = texture
	details = context.duplicate(true)
	queue_redraw()
func _process(delta: float) -> void:
	age += delta
	queue_redraw()
func _draw() -> void:
	if not enabled or style == null or age > style.duration: return
	var c := size * 0.5
	var t: float = 0.5 if still else clampf(age / style.duration,0,1)
	var ink: Color = style.ink
	if identity: draw_texture_rect(identity,Rect2(c - Vector2(18,18),Vector2(36,36)),false)
	if _draw_c04(c,t,ink): return
	if _draw_c03(c,t,ink): return
	if _draw_v08(c,t,ink): return
	match style.shape:
		"lock":
			for x in [-24,0,24]: draw_line(c+Vector2(x,-26),c+Vector2(x,26),ink,2)
			draw_rect(Rect2(c+Vector2(-8,-7),Vector2(16,14)),ink,false,3)
		"sweep":
			for j in 3: draw_line(c+Vector2(-26,-22+j*7+t*30),c+Vector2(26,-28+j*7+t*30),ink,2)

		"echo":
			draw_arc(c,20+8*t,0,TAU,24,ink,2)
			draw_arc(c,12+10*t,0,TAU,24,ink,2)
		"tickets":
			for j in 2:
				var offset := Vector2(-24+j*8,-22+j*8+(1-t)*5)
				draw_rect(Rect2(c+offset,Vector2(38,34)),ink,false,2)
				for dot in 4: draw_line(c+offset+Vector2(8+dot*7,8),c+offset+Vector2(10+dot*7,8),ink,2)
		"growth":
			for j in 3:
				var y := 24.0-j*10-t*8
				draw_line(c+Vector2(-24,y),c+Vector2(-13,y),ink,3)
				draw_line(c+Vector2(13,y),c+Vector2(24,y),ink,3)
			draw_line(c+Vector2(0,-28),c+Vector2(0,-20),ink,3)
			draw_line(c+Vector2(0,-28),c+Vector2(-5,-23),ink,3)
			draw_line(c+Vector2(0,-28),c+Vector2(5,-23),ink,3)
		"hourglass":
			var points := PackedVector2Array([c+Vector2(-23,-25),c+Vector2(23,-25),c+Vector2(13,0),c+Vector2(23,25),c+Vector2(-23,25),c+Vector2(-13,0),c+Vector2(-23,-25)])
			draw_polyline(points,ink,2)
			draw_line(c+Vector2(-18,22-t*4),c+Vector2(18,22-t*4),ink,3)
		"coin":
			var at := c+Vector2(0,-24-5*sin(t*PI))
			draw_circle(at,5,ink)
			draw_line(at+Vector2(0,-3),at+Vector2(0,3),Color("604626"),2)
			draw_arc(c+Vector2(0,23),10,0,PI,12,ink,2)
		"coins":
			for j in 3:
				var angle := -PI*0.75+j*PI*0.25
				var at := c+Vector2(cos(angle),sin(angle))*(20+8*t)
				draw_circle(at,5,ink)
				draw_line(at+Vector2(0,-3),at+Vector2(0,3),Color("604626"),2)
		"brace":
			for side in [-1,1]:
				var x: float = side*(28-4*t)
				draw_polyline(PackedVector2Array([c+Vector2(x-side*7,-24),c+Vector2(x,-24),c+Vector2(x,24),c+Vector2(x-side*7,24)]),ink,3)
		"tabs":
			for j in 3:
				var y := -24.0+j*10-t*4
				draw_rect(Rect2(c+Vector2(18,y),Vector2(9,7)),ink,false,2)
			draw_line(c+Vector2(-23,-24),c+Vector2(-23,24),ink,3)
		"isolate":
			for x in [-1,1]:
				for y in [-1,1]:
					var at := c+Vector2(x,y)*(28-t*4)
					draw_line(at,at-Vector2(x*9,0),ink,3)
					draw_line(at,at-Vector2(0,y*9),ink,3)
		"flag":
			draw_line(c+Vector2(-26,26),c+Vector2(-26,-26),ink,3)
			for x in 4:
				for y in 2:
					if (x+y)%2 == 0: draw_rect(Rect2(c+Vector2(-23+x*7,-26+y*7),Vector2(6,6)),ink)
		"feathers":
			for j in 3:
				var angle := -PI*0.75+j*PI*0.25
				var tip := c+Vector2(cos(angle),sin(angle))*(22+6*t)
				var tangent := Vector2(-sin(angle),cos(angle))*4
				draw_colored_polygon(PackedVector2Array([tip,tip+tangent+Vector2(0,8),c+Vector2(0,-14),tip-tangent+Vector2(0,8)]),ink)
		"clock":
			draw_arc(c,27,-PI*0.5,-PI*0.5+TAU*(1-t*0.6),24,ink,3)
			draw_line(c+Vector2(0,-27),c+Vector2(0,-20),ink,3)
			draw_line(c+Vector2(21,20),c+Vector2(26,25),ink,4)
		"pips":
			for j in 4:
				var at := c+Vector2(-21+j*14,-26)
				draw_rect(Rect2(at,Vector2(7,7)),ink,j <= int(t*4))
		"halves":
			var gap := 7*(1-t)
			draw_arc(c-Vector2(gap,0),26,PI*0.5,PI*1.5,16,ink,3)
			draw_arc(c+Vector2(gap,0),26,-PI*0.5,PI*0.5,16,ink,3)
			draw_line(c+Vector2(0,21),c+Vector2(0,28),ink,3)
		"gable":
			draw_polyline(PackedVector2Array([c+Vector2(-27,-17),c+Vector2(0,-29+3*t),c+Vector2(27,-17)]),ink,3)
			draw_line(c+Vector2(16,-22),c+Vector2(16,-29),ink,4)
			draw_line(c+Vector2(-25,24),c+Vector2(25,24),ink,3)
		"hook":
			draw_arc(c,26,PI*0.2,PI*(1.1+0.5*t),24,ink,3)
			draw_line(c+Vector2(-25,-8),c+Vector2(-18,-5),ink,3)
		"nib":
			draw_polyline(PackedVector2Array([c+Vector2(-26,24),c+Vector2(-23,-16),c+Vector2(-12,-27),c+Vector2(8,-27)]),ink,3)
			draw_colored_polygon(PackedVector2Array([c+Vector2(10,-27),c+Vector2(20,-23),c+Vector2(11,-18)]),ink)
		"impact":
			for j in 4:
				var angle := j*PI*0.5+PI*0.25
				var dir := Vector2(cos(angle),sin(angle))
				var tangent := Vector2(-dir.y,dir.x)*5
				draw_colored_polygon(PackedVector2Array([c+dir*(20+7*(1-t)),c+dir*30+tangent,c+dir*30-tangent]),ink)
		"elastic":
			var bend := sin(t*PI)*9
			draw_polyline(PackedVector2Array([c+Vector2(-28,20),c+Vector2(-24,-12-bend),c+Vector2(0,-25),c+Vector2(24,-12-bend),c+Vector2(28,20)]),ink,3)
		"chips":
			for j in 4:
				var x := -24+j*16
				var y := 18+t*10-(j%2)*5
				draw_line(c+Vector2(x,y),c+Vector2(x+5,y+3),ink,3)
		"facets":
			for j in 4:
				var angle := j*PI*0.5
				var at := c+Vector2(cos(angle),sin(angle))*26
				var r := 3.0+2.0*sin(t*PI+j*0.7)
				draw_polyline(PackedVector2Array([at+Vector2(0,-r),at+Vector2(r,0),at+Vector2(0,r),at+Vector2(-r,0),at+Vector2(0,-r)]),ink,2)

func _draw_v08(c: Vector2, t: float, ink: Color) -> bool:
	var count := clampi(int(details.get("count",0)),0,10)
	var amount := float(details.get("amount",0))
	var caption := ""
	match style.shape:
		"tally":
			draw_polyline(PackedVector2Array([c+Vector2(-25,18),c+Vector2(-25,-27),c+Vector2(25,-27),c+Vector2(25,18)]),ink,2)
			var lit := count if still else ceili(count*ease(t,0.5))
			for j in lit:
				var at := c+Vector2(-20+(j%5)*9,-23+(j/5)*6)
				draw_line(at,at+Vector2(-2,4),ink,2)
			caption = "%d pins" % count
		"flame_tally":
			for side in [-1,1]:
				var x: float = side*24.0
				var rise := 3.0 if still else 6.0*sin(t*PI)
				draw_polyline(PackedVector2Array([c+Vector2(x,13),c+Vector2(x-4,5),c+Vector2(x+1,-9-rise),c+Vector2(x+5,5),c+Vector2(x,13)]),ink,2)
			caption = "streak %d" % int(details.get("streak",0))
		"standing":
			for j in count:
				var x := -24.0+j*48.0/maxi(1,count-1)
				draw_circle(c+Vector2(x,-26),1.7,ink)
				draw_line(c+Vector2(x,-23),c+Vector2(x,-18),ink,2)
			draw_polyline(PackedVector2Array([c+Vector2(-27,11),c+Vector2(-27,20),c+Vector2(27,20),c+Vector2(27,11)]),ink,3)
			caption = "%d stood" % count
		"jar_drop":
			var at := c+Vector2(0,-27+9*(0.8 if still else ease(t,0.5)))
			draw_circle(at,4,ink)
			draw_line(at+Vector2(0,-2),at+Vector2(0,2),Color("674c2a"),1)
			draw_arc(c+Vector2(0,-15),12,0,PI,12,ink,2)
			caption = "$%d" % int(amount)
		"banana_strike":
			draw_arc(c,25,PI*0.1,PI*(1.1+0.4*(1.0 if still else ease(t,0.5))),24,ink,3)
			var star := c+Vector2(0,-25)
			for j in 4:
				var dir := Vector2.from_angle(j*PI*0.5+PI*0.25)
				draw_line(star-dir*5,star+dir*5,ink,2)
			caption = "×"+String.num(amount,2)
		"plumb":
			var x := -25.0+(0.0 if still else 2.0*sin(t*PI))
			draw_line(c+Vector2(x-5,-26),c+Vector2(x+5,-26),ink,2)
			draw_line(c+Vector2(x,-26),c+Vector2(x,12),ink,2)
			draw_colored_polygon(PackedVector2Array([c+Vector2(x,11),c+Vector2(x+4,15),c+Vector2(x,22),c+Vector2(x-4,15)]),ink)
			caption = "+%d Mult" % int(amount)
		"cutter":
			draw_polyline(PackedVector2Array([c+Vector2(-23,-24),c+Vector2(24,-24),c+Vector2(24,18)]),ink,2)
			var end := c+Vector2(24,-24).lerp(Vector2(15,-15),1.0 if still else ease(t,0.5))
			draw_line(c+Vector2(24,-24),end,Color.WHITE,3)
			draw_line(c+Vector2(-25,-17),c+Vector2(-25,16),ink,2)
			caption = "%d Glass" % count
		"crack":
			for side in [-1,1]:
				var x: float = side*(23.0+(0.0 if still else 3.0*sin(t*PI)))
				draw_polyline(PackedVector2Array([c+Vector2(x,-25),c+Vector2(x-side*5,-12),c+Vector2(x+side*2,-4),c+Vector2(x-side*4,10)]),ink,2)
			draw_line(c+Vector2(-16,20),c+Vector2(16,20),Color("c39548"),3)
			caption = "%d → Wood" % int(details.get("position",0))
		_: return false
	var font := get_theme_default_font()
	var width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
	draw_string(font,c+Vector2(-width*0.5,31),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f1e4c6"))
	return true

func _draw_c03(c: Vector2, t: float, ink: Color) -> bool:
	var caption := ""
	match style.shape:
		"crown_last", "jewel_last":
			var zero: bool = details.get("zero",false)
			var color := Color("899199") if zero else ink
			var y := -20.0 if still or zero else -27.0 + 7.0*ease(t,0.5)
			draw_polyline(PackedVector2Array([c+Vector2(-24,y+5),c+Vector2(-27,y-7),c+Vector2(-16,y-2),c+Vector2(0,y-12),c+Vector2(16,y-2),c+Vector2(27,y-7),c+Vector2(24,y+5),c+Vector2(-24,y+5)]),color,2)
			if zero:
				draw_line(c+Vector2(-25,-13),c+Vector2(25,-13),color,2)
				caption = "%d: 0" % int(details.get("position",0))
			else:
				draw_line(c+Vector2(-22,21),c+Vector2(22,21),color,3)
				caption = "%d last · %s" % [int(details.get("last_fallen",0)),"+40" if style.shape=="crown_last" else "×2"]
				if style.shape=="jewel_last":
					for x in [-24,24]:
						draw_polyline(PackedVector2Array([c+Vector2(x,0),c+Vector2(x+4,6),c+Vector2(x,12),c+Vector2(x-4,6),c+Vector2(x,0)]),color,2)
		"split_leave":
			var leave := clampi(int(details.get("leave",0)),0,10)
			for j in leave:
				var x := -25.0+j*50.0/maxi(1,leave-1)
				draw_circle(c+Vector2(x,-25),2.2,ink)
				draw_line(c+Vector2(x,-22),c+Vector2(x,-17),ink,2)
			var close := 0.0 if still else 3.0*(1-ease(t,0.5))
			draw_polyline(PackedVector2Array([c+Vector2(-25-close,-12),c+Vector2(-25-close,19),c+Vector2(-16,19)]),ink,2)
			draw_polyline(PackedVector2Array([c+Vector2(25+close,-12),c+Vector2(25+close,19),c+Vector2(16,19)]),ink,2)
			caption = "leave %d · ×3" % leave
		"grade_pair":
			var grades: Array = details.get("grades",[])
			for j in grades.size():
				var at := c+Vector2(-15+j*30,-23)
				var graded: bool = grades[j] in ["sweet","perfect"]
				var color: Color = ink if graded else Color("899199")
				var progress := 1.0 if still else clampf(t*2-j*0.35,0,1)
				draw_arc(at,8,-PI*0.5,-PI*0.5+TAU*progress,20,color,2)
				if grades[j]=="perfect": draw_arc(at,11,0,TAU,20,color,1)
				var letter: String = {"sweet":"S","perfect":"P","clean":"C","miss":"–"}.get(grades[j],"?")
				draw_string(get_theme_default_font(),at+Vector2(-3,3),letter,HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)
			caption = "%d grades · +%d" % [int(details.get("count",0)),int(details.get("amount",0))]
		"back_four":
			for j in 4:
				var at := c+Vector2(-24+j*16,-25)
				var color: Color = ink if (j+7) in details.get("positions",[]) else Color("657078")
				draw_circle(at,2,color)
				draw_line(at+Vector2(0,3),at+Vector2(0,10),color,3)
				draw_string(get_theme_default_font(),c+Vector2(-27+j*16,22),str(j+7),HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)
			draw_line(c+Vector2(-28,-13),c+Vector2(28,-13),ink,2)
			caption = "%d back · +%d" % [int(details.get("count",0)),int(details.get("amount",0))]
		"half_target":
			var score := float(details.get("match_score",0))
			var half := float(details.get("match_target",0))*0.5
			var fraction := clampf(score/maxf(half,1),0,1)
			draw_rect(Rect2(c+Vector2(-27,-28),Vector2(54,7)),ink,false,1)
			draw_rect(Rect2(c+Vector2(-26,-27),Vector2(52*fraction*(1.0 if still else ease(t,0.5)),5)),ink)
			draw_line(c+Vector2(27,-31),c+Vector2(27,-17),ink,2)
			draw_string(get_theme_default_font(),c+Vector2(17,18),"×2",HORIZONTAL_ALIGNMENT_LEFT,-1,10,ink)
			caption = "%d < %s" % [int(score),String.num(half,1)]
		_: return false
	var font := get_theme_default_font()
	var width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
	draw_string(font,c+Vector2(-width*0.5,31),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f1e4c6"))
	return true

func _draw_c04(c:Vector2,t:float,ink:Color) -> bool:
	var caption := ""
	match style.shape:
		"chalk_pair":
			for i in 5:
				var drift:=0.0 if still else 4.0*sin(t*PI)
				draw_rect(Rect2(c+Vector2(-24+i*11,-25-drift*(i%2)),Vector2(3,3)),ink)
			caption="+%d · spare"%int(details.get("amount",0))
		"wax_curve":
			for offset in [-5,3]:draw_arc(c+Vector2(offset,-2),27,PI*1.08,PI*1.82,16,ink,2)
			caption="+%d · curved"%int(details.get("amount",0))
		"slot_coin":
			draw_rect(Rect2(c+Vector2(-26,-25),Vector2(52,6)),ink,false,2)
			var fall:=10.0 if still else 3.0+12.0*ease(t,.5)
			draw_circle(c+Vector2(23,-19+fall),6,ink)
			draw_line(c+Vector2(23,-23+fall),c+Vector2(23,-15+fall),Color("614526"),2)
			caption="$%d · bank"%int(details.get("amount",0))
		"cap_tick":
			draw_arc(c+Vector2(0,-15),24,PI,TAU,24,ink,2)
			draw_line(c+Vector2(-25,-15),c+Vector2(25,-15),ink,3)
			var y := 0.0 if still else -4.0*sin(t*PI)
			draw_line(c+Vector2(23,3+y),c+Vector2(23,13+y),ink,2)
			draw_line(c+Vector2(18,8+y),c+Vector2(28,8+y),ink,2)
			caption = "+%d Mult" % int(details.get("amount",0))
		"leaf_coin":
			var x := 21.0 if still else 16.0+9.0*ease(t,0.5)
			draw_circle(c+Vector2(x,-22),7,ink)
			draw_line(c+Vector2(x,-27),c+Vector2(x,-17),Color("614526"),2)
			draw_polyline(PackedVector2Array([c+Vector2(-26,-20),c+Vector2(-22,-9),c+Vector2(-28,0),c+Vector2(-20,13)]),ink,2)
			caption = "$%d · bank" % int(details.get("amount",0))
		"key_count":
			draw_polyline(PackedVector2Array([c+Vector2(-27,-24),c+Vector2(27,-24),c+Vector2(19,21),c+Vector2(-19,21),c+Vector2(-27,-24)]),ink,2)
			for j in mini(10,int(details.get("count",0))):
				draw_circle(c+Vector2(-22+(j%5)*11,-29+(j/5)*5),1.5,ink)
			caption = "%d down · +%d" % [int(details.get("count",0)),int(details.get("amount",0))]
		_:return false
	var font:=get_theme_default_font()
	var width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
	draw_string(font,c+Vector2(-width*.5,31),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("f1e4c6"))
	return true

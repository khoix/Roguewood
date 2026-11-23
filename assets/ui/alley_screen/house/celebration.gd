extends Control
## House storyboards. Not listed in the live manifest until all 20 pass.
signal finished
const Kit = preload("res://assets/ui/alley_screen/house/prop_kit.gd")
const RivalArt = preload("res://src/presentation/rival_art.gd")
const FONT = preload("res://assets/ui/fonts/PixelifySans.ttf")
@export var variant := "strike.pinwheel"
var context: Dictionary = {}
var elapsed := 0.0
var _done := true
var _portrait: Texture2D

func _ready() -> void:
	size = Vector2(252, 90)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)

func duration() -> float:
	return 3.0 if variant.begins_with("boss.") else (1.6 if variant.begins_with("spare.") else 1.8)

func play(with: Dictionary) -> void:
	context = with.duplicate(true)
	elapsed = 0.0
	_done = false
	_portrait = RivalArt.portrait(String(context.get("rival_id", "")), "defeated") if variant.begins_with("boss.") else null
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed = minf(elapsed + delta, duration())
	if not bool(context.get("reduced_motion", false)): queue_redraw()
	if elapsed >= duration(): _finish()

func skip() -> void:
	elapsed = duration()
	queue_redraw()
	_finish()

func _finish() -> void:
	if _done: return
	_done = true
	set_process(false)
	finished.emit()

func _word(text: String, rect: Rect2, font_size: int, color: Color) -> void:
	var fs := font_size
	while fs > 8 and FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rect.size.x:
		fs -= 1
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2(roundf(rect.position.x + (rect.size.x-width)*0.5), rect.position.y)
	draw_string(FONT,p+Vector2(1,2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Kit.WOOD)
	draw_string(FONT,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)

func _draw() -> void:
	Kit.stage(self)
	# Reduced motion is the final tableau for the entire lifetime; no time shader.
	var t := 1.0 if bool(context.get("reduced_motion", false)) else clampf(elapsed / (duration()*0.66), 0.0, 1.0)
	match variant:
		"strike.pinwheel": _pinwheel(t)
		"spare.last_chair": _last_chair(t)
		"boss.surveyor.tape": _surveyor(t)
		"strike.domino": _domino(t)
		"strike.curtain": _curtain(t)
		"strike.score_stamp": _stamp(t)
		"strike.constellation": _constellation(t)
		"spare.magnet": _magnet(t)
		"spare.bookend": _bookend(t)
		"spare.delivery": _delivery(t)
		"spare.lasso": _lasso(t)
		_: if variant.begins_with("boss."): _boss_story(t)

func _pinwheel(t: float) -> void:
	var turn := ease(t, 0.4) * TAU * 0.75
	# Ten long spokes are pins: the incoming ball drives the brass hub.
	for i in 10:
		var a := i * TAU / 10.0 + turn
		var p := Vector2(58,42) + Vector2(sin(a),-cos(a))*13.0
		Kit.pin(self,p,a,true)
	Kit.ball(self,Vector2(lerpf(18,58,minf(1,t*3)),64-t*22),turn)
	_word("STRIKE!",Rect2(105,45,128,28),30,Kit.LIGHT)
	_word("TEN OUT OF TEN",Rect2(109,62,120,12),10,Kit.IVORY)
	if t > 0.4:
		for i in 6:
			var x := 103+i*23
			var y := 16 + (i%3)*4 + int((1-t)*12)
			Kit.rect(self,x,y,3,2,Kit.TEAL if i%2 else Kit.GOLD)

func _last_chair(t: float) -> void:
	var pull := smoothstep(0.25,0.65,t)
	var fall := smoothstep(0.5,0.85,t)
	Kit.chair(self,Vector2(164+pull*45,63))
	Kit.pin(self,Vector2(174,lerpf(52,67,fall)),fall*PI*0.48,true)
	Kit.ball(self,Vector2(lerpf(137,229,pull),63),pull*TAU)
	_word("SPARE!",Rect2(17,42,126,28),29,Kit.LIGHT)
	_word("PLEASE, TAKE A SEAT",Rect2(17,60,126,12),9,Kit.IVORY)
	if t > 0.8: Kit.sparkle(self,Vector2(200,25))

func _surveyor(t: float) -> void:
	Kit.rect(self,21,14,63,56,Kit.GOLD)
	Kit.rect(self,24,17,57,50,Kit.WOOD)
	if _portrait != null:
		draw_texture_rect(_portrait,Rect2(26,18,53,49),false)
	# The tape retracts from the title side into a comically oversized frame loop.
	var coil := smoothstep(0.1,0.8,t)
	var points := PackedVector2Array()
	for i in 33:
		var a := i*TAU/32.0
		var loop := Vector2(53+cos(a)*37,42+sin(a)*29)
		var straight := Vector2(34+i*5,69)
		points.append(straight.lerp(loop,coil).round())
	Kit.tape(self,points)
	Kit.rect(self,81,57,16,14,Kit.WOOD)
	Kit.rect(self,83,59,12,10,Kit.GOLD)
	Kit.rect(self,87,62,4,4,Kit.INK)
	_word(String(context.get("rival_name","The Surveyor")).to_upper(),Rect2(102,29,132,16),15,Kit.IVORY)
	_word("DEFEATED!",Rect2(101,51,134,24),24,Kit.LIGHT)
	_word("BEYOND MEASURE",Rect2(103,65,130,12),10,Kit.TEAL)

func _domino(t: float) -> void:
	_word("STRIKE!",Rect2(44,32,166,26),28,Kit.LIGHT)
	for i in 10:
		var fall := smoothstep(i*0.055,i*0.055+0.3,t)
		Kit.pin(self,Vector2(22+i*19,65),fall*1.1,true)
	# Last pin meets the bell; two steady rays, never a brightness flash.
	var hit := smoothstep(0.8,1.0,t)
	Kit.rect(self,224,39,2,26,Kit.GOLD)
	draw_colored_polygon(PackedVector2Array([Vector2(216,57),Vector2(218,44),Vector2(224,40),Vector2(231,44),Vector2(233,57)]),Kit.GOLD)
	Kit.rect(self,214,57,21,3,Kit.LIGHT)
	Kit.rect(self,223,60,4,3,Kit.WOOD)
	if hit > 0.5:
		Kit.sparkle(self,Vector2(212,40))
		Kit.sparkle(self,Vector2(236,39))

func _curtain(t: float) -> void:
	var open := smoothstep(0.0,0.4,t)
	_word("STRIKE!",Rect2(65,34,122,28),28,Kit.LIGHT)
	for i in 5:
		var angle := smoothstep(0.25,0.75,t)*(1 if i%2 else -1)*1.2
		Kit.pin(self,Vector2(36+i*43,65),angle)
	# Five partners emerge behind the front row before the synchronized bow.
	for i in 5:
		Kit.pin(self,Vector2(49+i*38,54),smoothstep(0.25,0.75,t)*1.2)
	Kit.ball(self,Vector2(126,62+sin(t*PI)*-7),smoothstep(0.7,1,t)*0.5)
	for side in [0,1]:
		var width := lerpf(114,13,open)
		var x := 12.0 if side == 0 else 240-width
		Kit.rect(self,x,12,width,58,Kit.WOOD)
		for stripe in range(0,int(width),6): Kit.rect(self,x+stripe,12,2,58,Color("966344"))
	Kit.rect(self,12,12,228,5,Kit.GOLD)

func _stamp(t: float) -> void:
	Kit.rect(self,22,23,80,46,Kit.WOOD)
	Kit.rect(self,25,20,74,46,Kit.IVORY)
	for x in range(30,96,13): Kit.rect(self,x,24,1,36,Color("b6a17f"))
	for y in range(29,65,10): Kit.rect(self,29,y,66,1,Color("b6a17f"))
	var impact := smoothstep(0.15,0.45,t)
	if impact > 0.8:
		draw_line(Vector2(44,31),Vector2(77,56),Kit.WOOD,5)
		draw_line(Vector2(77,31),Vector2(44,56),Kit.WOOD,5)
	var stamp_y := lerpf(10,35,impact)-smoothstep(0.55,0.85,t)*28
	Kit.rect(self,47,stamp_y-13,27,14,Kit.WOOD)
	Kit.rect(self,36,stamp_y,50,8,Kit.GOLD)
	Kit.rect(self,36,stamp_y+8,50,3,Kit.WOOD)
	_word("STRIKE!",Rect2(111,44,122,30),28,Kit.LIGHT)
	_word("STAMP OF APPROVAL",Rect2(109,62,126,12),9,Kit.IVORY)
	if t > 0.5:
		Kit.pin(self,Vector2(19,64),-0.3)
		Kit.pin(self,Vector2(103,64),0.3)

func _constellation(t: float) -> void:
	var points := PackedVector2Array([Vector2(36,25),Vector2(52,16),Vector2(74,16),Vector2(90,28),Vector2(96,46),Vector2(81,61),Vector2(60,64),Vector2(38,57),Vector2(28,42),Vector2(29,31)])
	for i in points.size():
		var rise := smoothstep(i*0.035,0.55+i*0.035,t)
		var p := Vector2(points[i].x,68).lerp(points[i],rise)
		if t < 0.65: Kit.pin(self,p,0.0)
		else: Kit.sparkle(self,p)
		if t > 0.6 and i > 0: draw_line(points[i-1],points[i],Kit.TEAL,1)
	if t > 0.7:
		for p in [Vector2(59,30),Vector2(71,34),Vector2(62,43)]: Kit.rect(self,p.x,p.y,3,3,Kit.IVORY)
	_word("STRIKE!",Rect2(110,43,124,30),28,Kit.LIGHT)
	_word("WRITTEN IN THE STARS",Rect2(107,61,130,12),9,Kit.TEAL)

func _magnet(t: float) -> void:
	var lift := smoothstep(0.2,0.75,t)
	Kit.pin(self,Vector2(191,lerpf(68,47,lift)),lift*PI*0.5,true)
	# Squared brass horseshoe, teal wrapped handle, ivory pole caps.
	Kit.rect(self,170,18,44,9,Kit.GOLD)
	Kit.rect(self,170,23,9,20,Kit.GOLD)
	Kit.rect(self,205,23,9,20,Kit.GOLD)
	Kit.rect(self,172,19,40,3,Kit.LIGHT)
	Kit.rect(self,181,17,22,11,Kit.TEAL)
	Kit.rect(self,170,40,9,5,Kit.IVORY)
	Kit.rect(self,205,40,9,5,Kit.IVORY)
	_word("SPARE!",Rect2(17,42,130,30),29,Kit.LIGHT)
	_word("AN ATTRACTIVE FINISH",Rect2(17,60,130,12),9,Kit.IVORY)
	if t > 0.8: Kit.sparkle(self,Vector2(225,32))

func _bookend(t: float) -> void:
	var close := smoothstep(0.15,0.75,t)
	var left := lerpf(151,174,close)
	var right := lerpf(222,204,close)
	Kit.pin(self,Vector2(194,52-close*8),0.0,true)
	Kit.rect(self,145,66,91,5,Kit.GOLD)
	for x in [left,right]:
		Kit.rect(self,x,39,10,26,Kit.WOOD)
		Kit.rect(self,x+2,40,6,23,Kit.GOLD)
		Kit.rect(self,x-3,63,16,3,Kit.GOLD)
	_word("SPARE!",Rect2(17,42,123,30),29,Kit.LIGHT)
	_word("CASE CLOSED",Rect2(17,60,123,12),10,Kit.IVORY)

func _delivery(t: float) -> void:
	var arrive := smoothstep(0,0.55,t)
	var tip := smoothstep(0.55,0.95,t)
	var x := lerpf(141,179,arrive)
	Kit.ball(self,Vector2(x-18,62),arrive*TAU)
	Kit.rect(self,x,58,28,5,Kit.GOLD)
	Kit.rect(self,x,46,3,13,Kit.GOLD)
	for wheel in [5,23]:
		Kit.rect(self,x+wheel,63,6,6,Kit.INK)
		Kit.rect(self,x+wheel+2,65,2,2,Kit.LIGHT)
	Kit.pin(self,Vector2(x+14+tip*23,53+tip*9),tip*1.5,true)
	Kit.rect(self,208,56,28,15,Kit.WOOD)
	Kit.rect(self,210,58,24,2,Kit.GOLD)
	_word("SPARE",Rect2(209,69,26,10),8,Kit.IVORY)
	_word("SPARE!",Rect2(17,42,121,30),29,Kit.LIGHT)
	_word("SPECIAL DELIVERY",Rect2(17,60,121,12),9,Kit.IVORY)

func _lasso(t: float) -> void:
	var pull := smoothstep(0.3,0.9,t)
	var x := lerpf(173,220,pull)
	var points := PackedVector2Array()
	for i in 25:
		var a := i*TAU/24.0
		points.append(Vector2(x+cos(a)*14,49+sin(a)*8).round())
	draw_polyline(points,Kit.GOLD,2)
	draw_line(Vector2(x+14,49),Vector2(241,38),Kit.GOLD,2)
	Kit.pin(self,Vector2(x,63),pull*0.4,true)
	# A little ivory arm tips a friendly farewell as the lane ribbon pulls away.
	if pull > 0.5:
		draw_line(Vector2(x+3,53),Vector2(x+13,43),Kit.IVORY,2)
		Kit.rect(self,x+11,39,4,4,Kit.IVORY)
	_word("SPARE!",Rect2(17,42,130,30),29,Kit.LIGHT)
	_word("THAT'S A WRAP",Rect2(17,60,130,12),10,Kit.IVORY)

func _broom(p: Vector2, angle: float) -> void:
	draw_set_transform(p.round(),angle)
	Kit.rect(self,-1,-24,3,30,Kit.GOLD)
	draw_colored_polygon(PackedVector2Array([Vector2(-4,2),Vector2(5,2),Vector2(11,14),Vector2(-10,14)]),Kit.GOLD)
	for x in range(-8,10,3): Kit.rect(self,x,7,1,7,Kit.WOOD)
	Kit.rect(self,-5,3,12,3,Kit.TEAL)
	draw_set_transform(Vector2.ZERO)

func _boss_story(t: float) -> void:
	var settle := smoothstep(0.1,0.85,t)
	var bow := sin(t*PI)*0.10 if variant == "boss.old_lou.encore" else 0.0
	draw_set_transform(Vector2(52,42),bow)
	Kit.rect(self,-31,-28,62,56,Kit.GOLD)
	Kit.rect(self,-28,-25,56,50,Kit.WOOD)
	if _portrait != null: draw_texture_rect(_portrait,Rect2(-26,-24,52,48),false)
	draw_set_transform(Vector2.ZERO)
	var name_parts := String(context.get("rival_name","Rival")).to_upper().split(",",false,1)
	if name_parts.size() == 2:
		_word(name_parts[0],Rect2(93,18,142,12),12,Kit.IVORY)
		_word(name_parts[1].strip_edges(),Rect2(93,28,142,10),10,Kit.TEAL)
	else:
		_word(name_parts[0],Rect2(93,24,142,16),14,Kit.IVORY)
	_word("DEFEATED!",Rect2(95,71,140,24),23,Kit.LIGHT)
	match variant:
		"boss.surveyor.level":
			Kit.rect(self,115,43,104,11,Kit.GOLD)
			Kit.rect(self,119,45,96,7,Kit.TEAL)
			for x in [143,187]: Kit.rect(self,x,44,2,9,Kit.INK)
			var bubble := Vector2(164,48-settle*18)
			draw_circle(bubble,5,Kit.IVORY)
			draw_circle(bubble+Vector2(1,0),3,Kit.TEAL)
			Kit.rect(self,149,bubble.y+5,53,4,Kit.GOLD)
			for x in range(151,201,5): Kit.rect(self,x,bubble.y+5,1,2,Kit.WOOD)
		"boss.custodian.sweep":
			var x := lerpf(116,183,settle)
			for i in 3: Kit.pin(self,Vector2(x+i*12,51),1.1,true)
			_broom(Vector2(x-13,42),0.5)
			Kit.rect(self,213,34,3,22,Kit.GOLD)
			draw_colored_polygon(PackedVector2Array([Vector2(201,48),Vector2(222,48),Vector2(232,58),Vector2(195,58)]),Kit.TEAL)
			if t > 0.8:
				draw_line(Vector2(214,47),Vector2(222,35),Kit.IVORY,2)
				Kit.sparkle(self,Vector2(226,33))
		"boss.custodian.polish":
			# A brass hand mirror becomes clear as the cloth passes across it.
			draw_circle(Vector2(163,41),17,Kit.GOLD)
			draw_circle(Vector2(163,41),14,Color("7cb4af").lerp(Kit.IVORY,settle*0.7))
			Kit.rect(self,180,39,25,5,Kit.GOLD)
			var cloth := Vector2(146+settle*66,35+sin(t*TAU)*5)
			Kit.rect(self,cloth.x,cloth.y,19,14,Kit.TEAL)
			Kit.rect(self,cloth.x+2,cloth.y+2,15,2,Kit.IVORY)
			if t > 0.7: Kit.sparkle(self,Vector2(158,36))
		"boss.proprietor.receipt":
			Kit.rect(self,119,29,70,lerpf(8,29,settle),Kit.IVORY)
			for y in range(33,int(32+settle*20),5): Kit.rect(self,124,y,57,1,Kit.WOOD)
			Kit.rect(self,118,56,73,3,Kit.GOLD)
			if t > 0.6:
				Kit.rect(self,165,35,60,20,Kit.WOOD)
				Kit.rect(self,167,37,56,16,Kit.GOLD)
				_word("PAID",Rect2(169,50,52,14),16,Kit.INK)
		"boss.proprietor.keys":
			Kit.rect(self,126,51,91,8,Kit.WOOD)
			Kit.rect(self,129,49,85,7,Kit.TEAL)
			draw_set_transform(Vector2(172,lerpf(24,40,settle)),(1-settle)*TAU)
			draw_arc(Vector2.ZERO,7,0,TAU,20,Kit.LIGHT,2)
			for i in 3:
				var x := -9+i*8
				Kit.rect(self,x,4,2,12,Kit.GOLD)
				Kit.rect(self,x,13,6,3,Kit.GOLD)
			draw_set_transform(Vector2.ZERO)
		"boss.old_lou.record":
			Kit.rect(self,106,31,52,25,Kit.WOOD)
			Kit.rect(self,108,33,48,21,Kit.GOLD)
			_word("OLD",Rect2(110,47,44,16),13,Kit.WOOD)
			var width := 58.0*absf(cos(settle*PI))
			Kit.rect(self,196-width/2,30,width,27,Kit.GOLD)
			if settle > 0.75:
				Kit.rect(self,174,34,44,18,Kit.IVORY)
				_word("NEW",Rect2(174,48,44,16),14,Kit.INK)
			if t > 0.8: Kit.sparkle(self,Vector2(229,36))
		"boss.old_lou.encore":
			for i in 6:
				var x := 111+i*22
				var clap := sin(t*TAU*2+i)*0.18 if t < 1 else 0.0
				Kit.pin(self,Vector2(x,55),clap)
				draw_line(Vector2(x-6,48),Vector2(x-10,41+clap*10),Kit.IVORY,2)
				draw_line(Vector2(x+6,48),Vector2(x+10,41-clap*10),Kit.IVORY,2)
		"boss.custodian_champion.crown":
			_broom(Vector2(142,44),-0.65)
			_broom(Vector2(192,44),0.65)
			# The wreath descends onto this champion's own portrait, never the regular Custodian.
			var center := Vector2(52,lerpf(3,41,settle))
			for i in 16:
				var a := i*TAU/16
				var p := center+Vector2(cos(a)*33,sin(a)*28)
				Kit.rect(self,p.x-2,p.y-2,5,4,Kit.GOLD if i%2 else Kit.LIGHT)
			draw_colored_polygon(PackedVector2Array([Vector2(153,42),Vector2(151,30),Vector2(161,36),Vector2(168,27),Vector2(175,36),Vector2(185,30),Vector2(183,42)]),Kit.LIGHT)
		"boss.custodian_champion.house_lights":
			for i in 12:
				var a := PI+i*PI/11
				var p := Vector2(169,57)+Vector2(cos(a)*61,sin(a)*28)
				Kit.rect(self,p.x-2,p.y-2,4,4,Kit.LIGHT if t > i*0.055 else Kit.WOOD)
			draw_colored_polygon(PackedVector2Array([Vector2(150,34),Vector2(188,34),Vector2(188,48),Vector2(169,58),Vector2(150,48)]),Kit.GOLD)
			_word("HOUSE",Rect2(151,46,36,12),10,Kit.INK)
			if t > 0.8: Kit.sparkle(self,Vector2(169,29))

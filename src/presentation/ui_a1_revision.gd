extends "res://src/presentation/ui_a1_composition.gd"
## Wave 10 standalone composition; all gameplay data remains a specimen.
@export_enum("Slow stars", "Constellations") var option:=0
@export var reduced:=false
@export var left_handed:=false
var folded:=false
var show_hand:=false
var show_details:=false
var corridor:=Rect2()
var backdrop:Control
func rebuild() -> void:
 super.rebuild()
 if stage==null:return
 backdrop=load("res://assets/ui/backdrops/house.gd").new()
 backdrop.size=size;backdrop.option=option;backdrop.reduced=reduced
 stage.add_child(backdrop);stage.move_child(backdrop,0)
func compact(index:int,rect:Rect2) -> void:
 var card:=Control.new();card.position=rect.position;card.size=rect.size;stage.add_child(card);cards.append(card)
 factory.image_at(card,load("res://assets/ui/cards/face-"+["common","uncommon","epic","common","rare"][index]+".svg"),Rect2(Vector2.ZERO,rect.size))
 for box in [Rect2(8,10,rect.size.x-16,24),Rect2(8,rect.size.y-42,rect.size.x-16,30)]:
  var paper:=ColorRect.new();paper.position=box.position;paper.size=box.size;paper.color=Color("f4e6cd");paper.mouse_filter=MOUSE_FILTER_IGNORE;card.add_child(paper)
 factory.image_at(card,Assets.slot(Cards.IDS[index],"card"),Rect2(14*rect.size.x/210,38,182*rect.size.x/210,224*rect.size.y/300-38))
 words(["House Ball","Ruby Pin","Crown Jewel","Nudge","Spotlight"][index],Rect2(rect.position+Vector2(10,14),Vector2(rect.size.x-20,20)),14,Color("101820"))
 words(["COMMON","UNCOMMON","EPIC","COMMON","RARE"][index],Rect2(rect.position+Vector2(10,rect.size.y-34),Vector2(rect.size.x-20,20)),14,Color("101820"))
func charms(rect:Rect2) -> void:
 frame("panel",rect)
 words("CHARMS",Rect2(rect.position+Vector2(16,12),Vector2(100,24)),18,Color("e7bc70"))
 for i in 3:
  factory.image_at(stage,Assets.slot(["charm.spare_jar","charm.consolation_prize","charm.crown_jewel"][i],"icon"),Rect2(rect.position+Vector2(112+i*44,10),Vector2(32,32)))
func throw_page(portrait:bool) -> void:
 var w:=size.x;var h:=size.y
 if portrait:
  lane_at(Rect2(24,354,w-48,510))
  corridor=Rect2(w*.30,354,w*.40,510)
  frame("hud",Rect2(24,88,w-48,136))
  words("HOUSE / DIVISION 1",Rect2(44,104,430,32),26)
  action("OPTIONS",Rect2(w-190,98,148,48))
  words("560 / 1,200",Rect2(44,164,370,36),30)
  frame("panel",Rect2(w-280,158,172,52));words("$24",Rect2(w-250,168,112,32),28)
  frame("slip",Rect2(24,238,320,48));words("70 x 8 = 560",Rect2(40,248,280,28),24,Color("101820"))
  frame("panel",Rect2(360,238,w-384,48));words("SURVEYOR / STRAIGHT",Rect2(374,250,w-412,26),18)
  charms(Rect2(24,298,w-48,48))
  frame("panel",Rect2(24,882,w-48,h-906))
  var x:=240.0 if left_handed else 44.0
  compact(0,Rect2(x,902,190,270));compact(3,Rect2(x+202,902,190,270))
  var tx:=44.0 if left_handed else 468.0
  words("DECK 12\nDISCARD 2",Rect2(tx,920,190,64),22)
  action("CYCLE",Rect2(tx,1016,184,56));action("INSPECT",Rect2(tx,1086,184,56))
  words("HOLD TO INSPECT",Rect2(44,1200,530,28),20,Color("95d9cb"))
 else:
  lane_at(Rect2(24,172,w-48,h-196))
  corridor=Rect2(w*.32,172,w*.36,h-196)
  frame("hud",Rect2(24,88,w-48,68))
  words("HOUSE / D1",Rect2(44,106,220,32),26)
  words("560 / 1,200",Rect2(w*.34,106,250,32),26)
  words("$24",Rect2(w-304,106,100,32),26)
  action("OPTIONS",Rect2(w-178,98,136,48))
  folded=w/h<1.5 or w*.19<240
  if folded:
   frame("hud",Rect2(24,160,w-48,68))
   var button:=action("HAND 4",Rect2(40,170,180,48));button.pressed.connect(func():show_hand=not show_hand;show_details=false;rebuild())
   var details_button:=action("SLIP / RIVAL / CHARMS",Rect2(w-380,170,340,48));details_button.pressed.connect(func():show_details=not show_details;show_hand=false;rebuild())
   if show_details:
    frame("slip",Rect2(w-300,244,276,140));words("LAST FRAME\n70 x 8 = 560",Rect2(w-280,264,236,100),24,Color("101820"))
    frame("panel",Rect2(w-300,404,276,250));words("THE SURVEYOR\nDead Straight\n\nCHARMS",Rect2(w-280,424,236,160),22)
    for i in 3:factory.image_at(stage,Assets.slot(["charm.spare_jar","charm.consolation_prize","charm.crown_jewel"][i],"icon"),Rect2(w-280+i*72,592,48,48))
   if show_hand:
    frame("panel",Rect2(24,236,w*.27, h-260))
    for i in 4:compact([0,1,3,0][i],Rect2(40+(i%2)*132,256+(i/2)*184,120,172))
    action("CYCLE",Rect2(40,h-82,120,48));action("INSPECT",Rect2(172,h-82,120,48))
   return
  var side:=floorf(w*.19)
  frame("panel",Rect2(24,172,side,h-196))
  words("HAND 4 / DECK 12",Rect2(40,188,side-24,28),18)
  for i in 4:compact([0,1,3,0][i],Rect2(40+(i%2)*112,230+(i/2)*178,104,166))
  action("CYCLE",Rect2(40,h-76,104,48));action("INSPECT",Rect2(152,h-76,104,48))
  var rx:=w-side-24
  frame("slip",Rect2(rx,172,side,148));words("LAST FRAME\n70 x 8\n560 BANKED",Rect2(rx+18,190,side-36,112),24,Color("101820"))
  frame("panel",Rect2(rx,336,side,142));words("THE SURVEYOR\nDead Straight\nNo curved throw",Rect2(rx+16,354,side-32,110),20)
  frame("panel",Rect2(rx,494,side,136));words("CHARMS",Rect2(rx+16,510,side-32,30),20)
  for i in 3:factory.image_at(stage,Assets.slot(["charm.spare_jar","charm.consolation_prize","charm.crown_jewel"][i],"icon"),Rect2(rx+20+i*66,550,48,48))
func shop_page(portrait:bool) -> void:
 if portrait:super.shop_page(portrait);return
 var w:=size.x
 frame("menu",Rect2(24,88,w-48,100));words("THE PRO SHOP",Rect2(48,108,480,52),40,Color("e7bc70"));words("$24",Rect2(w-150,118,100,44),32)
 var gap:float=(w-96)/3.0
 for i in 3:
  var x:=48+i*gap
  frame("shop",Rect2(x-12,210,gap-12,390))
  compact([1,2,4][i],Rect2(x+20,230,210,300))
  action(["$5 BUY","$11 BUY","$8 BUY"][i],Rect2(x+20,542,210,48))
 action("$2 REROLL",Rect2(36,size.y-84,260,56));action("TO THE LANES",Rect2(w-332,size.y-84,296,56))

func lane_at(rect:Rect2) -> void:
 super.lane_at(rect)
 panels[-1].hide()
 viewport.transparent_bg=true
 for node in viewport.get_child(0).get_children():
  if node is WorldEnvironment:node.environment.background_mode=Environment.BG_CLEAR_COLOR
 lane_camera.keep_aspect=Camera3D.KEEP_HEIGHT
 call_deferred("frame_camera")
func frame_camera() -> void:
 if not is_instance_valid(viewport) or not is_instance_valid(lane_camera):return
 for i in 200:
  var ratio:float=lane_camera.unproject_position(aim_ball.global_position).y/viewport.size.y
  if absf(ratio-.667)<.005:break
  lane_camera.rotation.x+=-.002 if ratio>.667 else .002

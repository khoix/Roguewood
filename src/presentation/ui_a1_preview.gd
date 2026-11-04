extends Control
## UI-A1 standalone visual target. No live game UI, rules or state changes.
const Assets = preload("res://src/presentation/item_assets.gd")
const DIR = "res://assets/ui/cards/"
const IDS = ["ball.house", "pin.ruby", "charm.crown_jewel", "consumable.nudge", "shop_upgrade.spotlight_sign"]
const RARITIES = ["common", "uncommon", "rare", "epic", "legendary"]
const SEALS = ["■", "Ⅱ", "◆", "✦", "♛"]
const HINTS = ["Reliable roll", "+2 on fall", "×2 · Crown last", "Move one pin", "Rarer stock"]
const DETAILS = ["Standard weight", "+10 Value", "Frame Mult", "Before roll 2", "This attempt"]
const SYMBOLS = ["value", "mult", "mult", "consumable", "money"]
var studies := false
var cards: Array[Control] = []
var labels: Array[Label] = []
var art_windows: Array[TextureRect] = []
var toggle: Button
var gallery: Control
func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 var bg := ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT);add_child(bg)
 var title := Label.new();title.text="ROGUEWOOD  /  THE HOUSE";title.position=Vector2(28,18);title.add_theme_font_size_override("font_size",28);title.modulate=Color("e7bc70");add_child(title)
 toggle=Button.new();toggle.text="Show rarity studies";toggle.position=Vector2(28,62);toggle.size=Vector2(250,48);add_child(toggle)
 toggle.pressed.connect(func():studies=not studies;rebuild())
 gallery=Control.new();add_child(gallery)
 resized.connect(func():call_deferred("rebuild"))
 rebuild()
func label_at(parent:Control, text:String, rect:Rect2, pixels:int, ink:Color) -> Label:
 var label:=Label.new();label.text=text;label.position=rect.position;label.size=rect.size
 label.add_theme_font_size_override("font_size",pixels);label.add_theme_color_override("font_color",ink)
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;parent.add_child(label);labels.append(label);return label
func image_at(parent:Control, texture:Texture2D, rect:Rect2) -> TextureRect:
 var image:=TextureRect.new();image.texture=texture;image.position=rect.position
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;parent.add_child(image);image.size=rect.size;return image
func rebuild() -> void:
 if gallery==null:return
 for child in gallery.get_children():gallery.remove_child(child);child.queue_free()
 cards.clear();labels.clear();art_windows.clear()
 toggle.text="Show catalogue cards" if studies else "Show rarity studies"
 var portrait:=size.y>size.x
 var card_size:=Vector2(240,344) if portrait else Vector2(210,300)
 var columns:=2 if portrait else 3
 var start:=Vector2((size.x-card_size.x*2-24)/2,158) if portrait else Vector2(size.x-3*card_size.x-72,64)
 if portrait:
  label_at(gallery,"MATERIAL STUDIES · NOT ITEM RARITIES" if studies else "THE COLLECTION · HOUSE EDITION",Rect2(28,118,size.x-56,28),18,Color("95d9cb"))
 else:
  label_at(gallery,"THE CARD\n\nPrinted ivory stock.\nBrass and petrol ink.\nArt takes the floor.\n\nValue    × Mult    $\n\n"+("Material studies;\nrarities are samples." if studies else "Catalogue rarities.\nFive item categories."),Rect2(28,146,470,370),24,Color("f4e6cd"))
  label_at(gallery,"UI-A1-A · STATIC TARGET\nFont and room kit: Session B",Rect2(28,582,460,80),18,Color("95d9cb"))
 for i in 6:
  var card:=Control.new();card.position=start+Vector2(i%columns*(card_size.x+24),i/columns*(card_size.y+24));card.size=card_size;gallery.add_child(card);cards.append(card)
  if i==5:
   image_at(card,load(DIR+"back.svg"),Rect2(Vector2.ZERO,card_size));continue
  Assets._ensure()
  var item:Dictionary=Assets._items[IDS[i]]
  var rarity:String=RARITIES[i] if studies else item.rarity
  var s:=card_size/Vector2(210,300)
  image_at(card,load(DIR+"face-"+rarity+".svg"),Rect2(Vector2.ZERO,card_size))
  var art:=image_at(card,Assets.slot(IDS[i],"card"),Rect2(Vector2(15,41)*s,Vector2(180,181)*s));art_windows.append(art)
  label_at(card,item.name,Rect2(Vector2(18,10)*s,Vector2(174,28)*s),20,Color("101820"))
  image_at(card,load(DIR+str(item.id).get_slice(".",0)+".svg"),Rect2(Vector2(17,44)*s,Vector2(26,26)*s))
  image_at(card,load(DIR+SYMBOLS[i]+".svg"),Rect2(Vector2(17,235)*s,Vector2(28,28)*s))
  label_at(card,HINTS[i],Rect2(Vector2(51,230)*s,Vector2(144,22)*s),16,Color("101820"))
  label_at(card,DETAILS[i],Rect2(Vector2(51,251)*s,Vector2(144,20)*s),14,Color("573a2e"))
  label_at(card,SEALS[RARITIES.find(rarity)]+" "+rarity.to_upper(),Rect2(Vector2(18,274)*s,Vector2(180,18)*s),14,Color("101820"))

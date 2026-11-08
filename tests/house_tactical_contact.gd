extends SceneTree
const Assets=preload("res://src/presentation/item_assets.gd")
const IDS=["consumable.double_take","consumable.called_shot","consumable.pin_count"]
var destination:=""
var glyphs:Array[Control]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 root.size=Vector2i(960,650);root.content_scale_size=root.size
 var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
 for i in 3:
  var id:String=IDS[i]
  var card:=Panel.new();card.position=Vector2(24+i*312,24);card.size=Vector2(288,602);card.add_theme_stylebox_override("panel",Assets.slot(id,"rarity_treatment"));bg.add_child(card)
  var title:=Label.new();title.text=id.get_slice(".",1).capitalize()+"\n"+("COMMON" if i==2 else "UNCOMMON");title.position=Vector2(16,10);title.add_theme_font_size_override("font_size",24);card.add_child(title)
  for entry in [["card",Vector2(18,80),Vector2(252,300)],["icon",Vector2(24,400),Vector2(48,48)],["reduced_motion",Vector2(90,400),Vector2(48,48)]]:
   var image:=TextureRect.new();image.texture=Assets.slot(id,entry[0]);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;card.add_child(image);image.position=entry[1];image.size=entry[2]
   if image.texture==null:quit(1);return
  var glyph:=preload("res://src/presentation/ability_glyph.gd").new();card.add_child(glyph);glyph.position=Vector2(105,474);glyph.size=Vector2(80,80);glyphs.append(glyph)
  glyph.show_cue(Assets.slot(id,"activation"),true,Assets.slot(id,"icon"),{"phase":"ball","count":7,"amount":35,"lit":true,"positions":[1]})
  var sound:AudioStreamWAV=Assets.slot(id,"sound")
  if sound==null or sound.mix_rate!=22050 or sound.get_length()<=0:quit(1);return
 for n in 12:await process_frame
 await capture("contact")
 for i in 3:glyphs[i].show_cue(Assets.slot(IDS[i],"activation"),false,Assets.slot(IDS[i],"icon"),{"phase":"ball","count":7,"amount":35,"lit":true,"positions":[1]})
 for n in 18:await process_frame
 await capture("motion")
 glyphs[1].show_cue(Assets.slot(IDS[1],"activation"),true,Assets.slot(IDS[1],"icon"),{"phase":"missed","lit":false,"zero":true})
 glyphs[2].show_cue(Assets.slot(IDS[2],"activation"),true,Assets.slot(IDS[2],"icon"),{"phase":"ball","count":10,"amount":50})
 for n in 3:await process_frame
 await capture("counted")
 if DisplayServer.get_name()!="headless":
  var image:=root.get_texture().get_image()
  var origin:Vector2=glyphs[1].global_position+glyphs[1].size*.5-Vector2(21,21)
  var grey_pixels:=0
  for y in 42:
   for x in 42:
    var pixel:Color=image.get_pixel(int(origin.x)+x,int(origin.y)+y)
    if maxf(pixel.r,maxf(pixel.g,pixel.b))<.2:continue
    if absf(pixel.r-pixel.g)>.01 or absf(pixel.g-pixel.b)>.01:
     push_error("Called Shot miss retains success colour");quit(1);return
    grey_pixels+=1
  if grey_pixels<5:push_error("Missing visible grey hand");quit(1);return
 print("ROGUEWOOD_H4A_CONTACT_OK");quit(0)
func capture(label:String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(destination.path_join(label+".png"))!=OK:quit(1)

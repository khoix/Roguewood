extends SceneTree
const Assets=preload("res://src/presentation/item_assets.gd")
const IDS=["charm.cleanup_crew","charm.lucky_seven"]
var destination:=""
var glyphs:Array[Control]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 root.size=Vector2i(960,650);root.content_scale_size=root.size
 var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
 for i in 2:
  var id:String=IDS[i]
  var card:=Panel.new();card.position=Vector2(24+i*468,24);card.size=Vector2(444,602);card.add_theme_stylebox_override("panel",Assets.slot(id,"rarity_treatment"));bg.add_child(card)
  var title:=Label.new();title.text=id.get_slice(".",1).capitalize()+"\nCOMMON";title.position=Vector2(16,10);title.add_theme_font_size_override("font_size",24);card.add_child(title)
  for entry in [["card",Vector2(64,80),Vector2(316,300)],["icon",Vector2(24,400),Vector2(48,48)],["reduced_motion",Vector2(90,400),Vector2(48,48)]]:
   var texture:=TextureRect.new();texture.texture=Assets.slot(id,entry[0]);texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;texture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;card.add_child(texture);texture.position=entry[1];texture.size=entry[2]
   if texture.texture==null:quit(1);return
  var glyph:=preload("res://src/presentation/ability_glyph.gd").new();card.add_child(glyph);glyph.position=Vector2(180,474);glyph.size=Vector2(80,80);glyphs.append(glyph)
  var details:Dictionary={"leave":3,"required":2,"positions":[7,8,10]} if i==0 else {"face":7,"down":7,"standing":3}
  glyph.show_cue(Assets.slot(id,"activation"),true,Assets.slot(id,"icon"),details)
  var sound:AudioStreamWAV=Assets.slot(id,"sound")
  if sound==null or sound.mix_rate!=22050 or sound.get_length()<=0:quit(1);return
 for n in 12:await process_frame
 await capture("contact")
 for glyph in glyphs:glyph.show_cue(glyph.style,false,glyph.identity,glyph.details)
 for n in 25:await process_frame
 await capture("motion")
 glyphs[0].show_cue(glyphs[0].style,true,glyphs[0].identity,{"leave":10,"required":2})
 glyphs[1].show_cue(glyphs[1].style,true,glyphs[1].identity,{"face":0,"down":6})
 for n in 3:await process_frame
 await capture("counted")
 print("ROGUEWOOD_H4B_CONTACT_OK");quit(0)
func capture(label:String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(destination.path_join(label+".png"))!=OK:quit(1)

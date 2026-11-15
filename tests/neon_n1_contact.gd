extends SceneTree
const Assets=preload("res://src/presentation/item_assets.gd")
var ids=["ball.oilskin","ball.laser","pin.tempo"]
var destination:=""
var glyphs:Array[Control]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--artifact-dir="):destination=arg.trim_prefix("--artifact-dir=")
 root.size=Vector2i(960,660);root.content_scale_size=root.size
 var bg:=ColorRect.new();bg.color=Color("101820");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(bg)
 for i in ids.size():
  var id:String=ids[i]
  var card:=preload("res://src/presentation/card_view.gd").new()
  bg.add_child(card);card.position=Vector2(35+i*310,22);card.size=Vector2(270,386);card.set_item(id)
  if card.art_pending:push_error("Missing card "+id);quit(1);return
  for entry in [["icon",Vector2(70+i*310,430)],["reduced_motion",Vector2(140+i*310,430)]]:
   var icon:=TextureRect.new();icon.texture=Assets.slot(id,entry[0]);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   bg.add_child(icon);icon.position=entry[1];icon.size=Vector2(44,44)
  var glyph:=preload("res://src/presentation/ability_glyph.gd").new();bg.add_child(glyph);glyph.position=Vector2(130+i*310,520);glyph.size=Vector2(64,64);glyphs.append(glyph)
  if not Assets.slot(id,"sound") is AudioStreamWAV:push_error("Missing audio "+id);quit(1);return
 for count in [0,1,2]:
  for i in ids.size():glyphs[i].show_cue(Assets.slot(ids[i],"activation"),true,Assets.slot(ids[i],"icon"),_context(ids[i],count))
  for n in 3:await process_frame
  await capture("count_%d"%count)
 for i in ids.size():glyphs[i].show_cue(Assets.slot(ids[i],"activation"),false,Assets.slot(ids[i],"icon"),_context(ids[i],2))
 for n in 12:await process_frame
 await capture("motion")
 print("ROGUEWOOD_NEON_N1_CONTACT_OK");quit(0)
func capture(label:String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(destination.path_join(label+".png"))!=OK:quit(1)

func _context(id:String,count:int) -> Dictionary:
 var amount:float=count*(20 if id=="pin.tempo" else 4 if id=="charm.neon_sign" else 3)
 if id=="ball_mod.blacklight":amount=1.5
 if id=="ball_mod.bumper_guard":amount=2
 return {"count":count,"amount":amount}

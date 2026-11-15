extends RefCounted
static func run() -> Array[String]:
 var failures:Array[String]=[]
 var world:=Node3D.new()
 var wall:=StaticBody3D.new();wall.name="Kickback";world.add_child(wall)
 wall.physics_material_override=PhysicsMaterial.new()
 var physical:=wall.physics_material_override
 var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();wall.add_child(shape)
 var box:=shape.shape
 var mesh:=MeshInstance3D.new();mesh.mesh=BoxMesh.new();wall.add_child(mesh)
 var original:=StandardMaterial3D.new();mesh.material_override=original
 var theme=preload("res://src/presentation/league_theme.gd").for_league("league.house")
 theme.dress_lane(world,"lane.house")
 if mesh.material_override!=original:failures.append("Neon finish leaked into House")
 theme.manifest.league_id="league.neon"
 var before:=wall.transform
 theme.dress_lane(world,"lane.house")
 if not mesh.get_meta("neon_pin_deck",false):failures.append("Neon finish not bound")
 if wall.physics_material_override!=physical or shape.shape!=box or wall.transform!=before or wall.get_child_count()!=2:
  failures.append("Cosmetic deck finish changed physical body")
 world.free();theme.free()
 return failures

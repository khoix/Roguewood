extends Node3D
## Cosmetic follow-through only; the parent rigid body remains authoritative.
var reduced:=false
var activated:=false
var rock_age:=3.0
func _ready() -> void:
 var mesh:=MeshInstance3D.new();mesh.mesh=preload("res://src/presentation/lane_dressing.gd").new()._lathe()
 mesh.material_override=load("res://assets/items/d09/oak-material.tres");add_child(mesh)
func _process(delta:float) -> void:
 var body:=get_parent() as RigidBody3D
 if body==null:return
 if not activated and body.linear_velocity.length()>.3 and body.get_colliding_bodies().any(func(other):return other is RigidBody3D):
  activated=true;rock_age=0.0
 rock_age+=delta
 # A small damped two-second roll of the wood skin, never collision geometry.
 rotation.z=0.0 if reduced or rock_age>=2.0 else sin(rock_age*9.0)*.035*pow(1.0-rock_age/2.0,2)

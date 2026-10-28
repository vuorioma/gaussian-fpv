# A Map: one or more splat files of a real-world place, each placed by its own
# GaussianSplatNode child, plus what the Drone needs to fly in it. Everything
# here is in Map space, in meters; scale each splat node so it reads in meters.
class_name Map
extends Node3D

## The box the Drone's flyable space is confined to.
@export var bounds := AABB(Vector3(-10, -2, -10), Vector3(20, 10, 20))

## Where the Drone starts and returns to on reset. Only position and heading
## are used, so the Drone always spawns level.
@export var spawn_point: Marker3D

func get_spawn_transform() -> Transform3D:
	var spawn := spawn_point.global_transform if spawn_point else global_transform
	var forward := -spawn.basis.z
	forward.y = 0.0
	if forward.is_zero_approx():
		forward = Vector3.FORWARD
	return Transform3D(Basis.looking_at(forward), spawn.origin)

func get_global_bounds() -> AABB:
	return global_transform * bounds

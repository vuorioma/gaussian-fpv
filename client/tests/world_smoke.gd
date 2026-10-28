# World smoke test: runs the World scene with the Drone held at its Spawn
# Point, pitched forward by its Uptilt so the camera looks level, then writes
# what the camera sees to res://tests/ and quits.
# Run: godot --path client -s res://tests/world_smoke.gd
extends SceneTree

const WORLD_SCENE := preload("res://world/world.tscn")
const FRAMES := 120

var _frame := 0
var _world: World

func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	_world = WORLD_SCENE.instantiate()
	root.add_child(_world)

func _process(_delta: float) -> bool:
	# Without throttle the Drone would fall, so keep it parked at the spawn.
	_world.drone.reset()
	_world.drone.rotate_object_local(Vector3.RIGHT, -deg_to_rad(_world.drone.uptilt_deg))
	_frame += 1
	if _frame < FRAMES:
		return false
	print("spawn: ", _world.drone.global_transform.origin, " bounds: ", _world.drone.bounds)
	var path := ProjectSettings.globalize_path("res://tests/world_smoke.png")
	root.get_texture().get_image().save_png(path)
	print("screenshot: ", path)
	return true

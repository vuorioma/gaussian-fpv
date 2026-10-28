# The World: persistent home of the Drone, into which one Map at a time is
# injected and swapped.
class_name World
extends Node3D

@export var initial_map: PackedScene

var map: Map

@onready var drone: Drone = $Drone

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if initial_map:
		load_map(initial_map)

# Escape frees the mouse; clicking back into the window captures it again.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func load_map(scene: PackedScene) -> void:
	if map:
		remove_child(map)
		map.queue_free()
	map = scene.instantiate()
	add_child(map)
	drone.bounds = map.get_global_bounds()
	drone.spawn_transform = map.get_spawn_transform()
	drone.reset()

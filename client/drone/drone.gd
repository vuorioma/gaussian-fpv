# The Drone, flown in Acro: sticks command body rotation rates, nothing ever
# levels it, and throttle is raw thrust against gravity.
class_name Drone
extends CharacterBody3D

const GRAVITY := 9.81

## Fixed upward angle of the camera relative to the body, in degrees.
@export_range(0.0, 60.0) var uptilt_deg := 30.0

@export_group("Rates")
## Rotation rate at full stick deflection, in degrees per second.
@export var max_rate_deg := Vector3(600, 450, 600) # pitch, yaw, roll
## 0 is linear; higher softens the stick around center.
@export_range(0.0, 1.0) var expo := 0.4

@export_group("Thrust")
## Full-throttle thrust as a multiple of the Drone's weight.
@export var thrust_to_weight := 4.0
@export var linear_drag := 0.1
@export var quadratic_drag := 0.02

@export_group("Keyboard and Mouse")
## How fast the throttle rises while the throttle key is held, per second.
@export var keyboard_throttle_rise := 0.6
## How fast the throttle falls back to zero once the key is released, per second.
@export var keyboard_throttle_fall := 1.5
## Body rotation per pixel of mouse movement, in degrees.
@export var mouse_sensitivity_deg := 0.15
## When on, moving the mouse up pitches the nose down, like a stick.
@export var mouse_invert_pitch := false

## Set by the World from the current Map.
var bounds := AABB()
var spawn_transform := Transform3D.IDENTITY

var _keyboard_throttle := 0.0
var _mouse_motion := Vector2.ZERO

@onready var camera: Camera3D = $Camera

func _ready() -> void:
	DroneInput.register_actions()
	camera.rotation_degrees.x = uptilt_deg

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_motion += event.screen_relative

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("drone_reset"):
		reset()
		return
	_apply_mouse_rotation()
	simulate(_read_sticks(delta), delta)

func reset() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	_keyboard_throttle = 0.0
	_mouse_motion = Vector2.ZERO
	reset_physics_interpolation()

## Advances the flight model by delta. sticks is (pitch, yaw, roll, throttle):
## pitch, yaw and roll in [-1, 1] with positive meaning nose down, nose right
## and roll right; throttle in [0, 1].
func simulate(sticks: Vector4, delta: float) -> void:
	# Godot's body frame looks down -Z with +Y up, so all three positive stick
	# directions are negative rotations about their axes.
	var rates := -Vector3(
		deg_to_rad(max_rate_deg.x) * _apply_expo(sticks.x),
		deg_to_rad(max_rate_deg.y) * _apply_expo(sticks.y),
		deg_to_rad(max_rate_deg.z) * _apply_expo(sticks.z))
	if not rates.is_zero_approx():
		var body_rotation := Basis(rates.normalized(), rates.length() * delta)
		basis = (basis * body_rotation).orthonormalized()

	var thrust := basis.y * clampf(sticks.w, 0.0, 1.0) * thrust_to_weight * GRAVITY
	var drag := -velocity * (linear_drag + quadratic_drag * velocity.length())
	velocity += (thrust + Vector3.DOWN * GRAVITY + drag) * delta
	move_and_slide()
	_confine_to_bounds()

func _confine_to_bounds() -> void:
	if not bounds.has_volume():
		return
	var lower := bounds.position
	var upper := bounds.end
	for axis in 3:
		if global_position[axis] < lower[axis]:
			global_position[axis] = lower[axis]
			velocity[axis] = maxf(velocity[axis], 0.0)
		elif global_position[axis] > upper[axis]:
			global_position[axis] = upper[axis]
			velocity[axis] = minf(velocity[axis], 0.0)

# The mouse turns the body directly rather than commanding a rate: moving it
# right rolls right and, unless inverted, moving it up pitches the nose up.
func _apply_mouse_rotation() -> void:
	if _mouse_motion.is_zero_approx():
		return
	var radians := _mouse_motion * deg_to_rad(mouse_sensitivity_deg)
	_mouse_motion = Vector2.ZERO
	var pitch := radians.y if mouse_invert_pitch else -radians.y
	rotate_object_local(Vector3.RIGHT, pitch)
	rotate_object_local(Vector3.BACK, -radians.x)

func _apply_expo(stick: float) -> float:
	return stick * (1.0 - expo + expo * stick * stick)

func _read_sticks(delta: float) -> Vector4:
	if Input.is_action_pressed("drone_throttle_key"):
		_keyboard_throttle = minf(_keyboard_throttle + keyboard_throttle_rise * delta, 1.0)
	else:
		_keyboard_throttle = maxf(_keyboard_throttle - keyboard_throttle_fall * delta, 0.0)
	# The throttle stick rests at the bottom on a radio, so map its full travel
	# onto [0, 1] rather than treating it as centered. With no joypad the axis
	# reads 0, which would otherwise mean half throttle.
	var stick_throttle := 0.0
	if not Input.get_connected_joypads().is_empty():
		stick_throttle = (Input.get_axis("drone_throttle_down", "drone_throttle_up") + 1.0) * 0.5
	return Vector4(
		Input.get_axis("drone_pitch_back", "drone_pitch_forward"),
		Input.get_axis("drone_yaw_left", "drone_yaw_right"),
		Input.get_axis("drone_roll_left", "drone_roll_right"),
		maxf(stick_throttle, _keyboard_throttle))

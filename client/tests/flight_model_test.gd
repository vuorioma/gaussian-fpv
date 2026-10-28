# Flight model checks for the Drone's Acro simulation, run headless.
# Run: godot --headless --path client -s res://tests/flight_model_test.gd
extends SceneTree

const DRONE_SCENE := preload("res://drone/drone.tscn")
const DT := 1.0 / 240.0

var _failures := 0

func _initialize() -> void:
	# Nodes added here aren't inside the tree until the first frame.
	_run_tests.call_deferred()

func _run_tests() -> void:
	_test_hover_throttle_holds_altitude()
	_test_zero_throttle_falls()
	_test_stick_directions()
	_test_never_self_levels()
	_test_bounds_confine()
	_test_throttle_key_rises_and_falls()
	_test_mouse_directions()
	print("FAILED: %d" % _failures if _failures else "all flight model tests passed")
	quit(1 if _failures else 0)

func _make_drone() -> Drone:
	var drone: Drone = DRONE_SCENE.instantiate()
	root.add_child(drone)
	drone.global_transform = Transform3D.IDENTITY
	return drone

func _run(drone: Drone, sticks: Vector4, seconds: float) -> void:
	for i in int(seconds / DT):
		drone.simulate(sticks, DT)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)

func _test_hover_throttle_holds_altitude() -> void:
	var drone := _make_drone()
	_run(drone, Vector4(0, 0, 0, 1.0 / drone.thrust_to_weight), 2.0)
	_check(absf(drone.global_position.y) < 0.01, "hover throttle drifted to y=%f" % drone.global_position.y)
	drone.free()

func _test_zero_throttle_falls() -> void:
	var drone := _make_drone()
	_run(drone, Vector4.ZERO, 1.0)
	_check(drone.global_position.y < -3.0, "zero throttle only fell to y=%f" % drone.global_position.y)
	drone.free()

func _test_stick_directions() -> void:
	var cases := {
		"pitch forward tilts the nose down": [Vector4(1, 0, 0, 0), func(b: Basis): return (-b.z).y < -0.1],
		"yaw right turns the nose right": [Vector4(0, 1, 0, 0), func(b: Basis): return (-b.z).x > 0.1],
		"roll right drops the right side": [Vector4(0, 0, 1, 0), func(b: Basis): return b.x.y < -0.1],
	}
	for name in cases:
		var drone := _make_drone()
		_run(drone, cases[name][0], 0.1)
		_check(cases[name][1].call(drone.global_basis), name)
		drone.free()

func _test_never_self_levels() -> void:
	var drone := _make_drone()
	_run(drone, Vector4(0, 0, 1, 0.25), 0.1)
	var tilted := drone.global_basis
	_run(drone, Vector4(0, 0, 0, 0.25), 1.0)
	_check(drone.global_basis.is_equal_approx(tilted), "attitude changed with centered sticks")
	drone.free()

func _test_bounds_confine() -> void:
	var drone := _make_drone()
	drone.bounds = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	_run(drone, Vector4(0, 0, 0, 1), 2.0)
	_check(drone.global_position.y <= 1.0 + 1e-4, "climbed out of bounds to y=%f" % drone.global_position.y)
	_check(drone.velocity.y <= 0.0, "still climbing at the bounds")
	drone.free()

func _test_throttle_key_rises_and_falls() -> void:
	var drone := _make_drone()
	Input.action_press("drone_throttle_key")
	for i in 240:
		drone._read_sticks(DT)
	var held := drone._read_sticks(DT).w
	_check(held > 0.5, "holding the throttle key only reached %f" % held)
	Input.action_release("drone_throttle_key")
	for i in 240:
		drone._read_sticks(DT)
	var released := drone._read_sticks(DT).w
	_check(released == 0.0, "throttle stayed at %f after releasing the key" % released)
	drone.free()

func _test_mouse_directions() -> void:
	var cases := {
		"mouse up pitches the nose up": [Vector2(0, -50), func(b: Basis): return (-b.z).y > 0.1],
		"mouse right rolls right": [Vector2(50, 0), func(b: Basis): return b.x.y < -0.1],
	}
	for name in cases:
		var drone := _make_drone()
		drone._mouse_motion = cases[name][0]
		drone._apply_mouse_rotation()
		_check(cases[name][1].call(drone.global_basis), name)
		drone.free()

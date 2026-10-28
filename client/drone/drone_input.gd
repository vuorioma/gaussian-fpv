# The Drone's input actions, registered in code so the bindings stay readable.
# Sticks follow Mode 2 on the standard gamepad layout: left stick is throttle
# and yaw, right stick is pitch and roll. Radios connected over USB report
# their own axis order, so they may need rebinding.
class_name DroneInput

const STICK_DEADZONE := 0.02

static func register_actions() -> void:
	if InputMap.has_action("drone_reset"):
		return
	_add_axis("drone_throttle_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("drone_throttle_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_axis("drone_yaw_left", JOY_AXIS_LEFT_X, -1.0, KEY_A)
	_add_axis("drone_yaw_right", JOY_AXIS_LEFT_X, 1.0, KEY_D)
	_add_axis("drone_pitch_forward", JOY_AXIS_RIGHT_Y, -1.0, KEY_UP)
	_add_axis("drone_pitch_back", JOY_AXIS_RIGHT_Y, 1.0, KEY_DOWN)
	_add_axis("drone_roll_left", JOY_AXIS_RIGHT_X, -1.0, KEY_LEFT)
	_add_axis("drone_roll_right", JOY_AXIS_RIGHT_X, 1.0, KEY_RIGHT)
	_add_keys("drone_throttle_key", [KEY_W])
	_add_keys("drone_reset", [KEY_R])
	_add_button("drone_reset", JOY_BUTTON_START)
	_add_keys("release_mouse", [KEY_ESCAPE])

static func _add_axis(action: StringName, axis: JoyAxis, direction: float, key := KEY_NONE) -> void:
	InputMap.add_action(action, STICK_DEADZONE)
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = direction
	InputMap.action_add_event(action, motion)
	if key != KEY_NONE:
		_add_key_event(action, key)

static func _add_keys(action: StringName, keys: Array[Key]) -> void:
	InputMap.add_action(action)
	for key in keys:
		_add_key_event(action, key)

static func _add_button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

static func _add_key_event(action: StringName, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

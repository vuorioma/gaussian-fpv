# Render smoke test: loads a splat through GDGS, renders for a while, then
# writes a screenshot and the average fps to res://tests/ and quits.
# Run: godot --path client -s res://tests/render_smoke.gd
extends SceneTree

const SPLAT_PATH := "res://maps/truck/truck.splat"
const COMPOSITOR_EFFECT_SCRIPT := preload("res://addons/gdgs/runtime/compositor/gaussian_compositor_effect.gd")
const WARMUP_FRAMES := 120
const MEASURE_FRAMES := 300
const CAMERA_OFFSET := Vector3(0, 1.5, 6)

var _frame := 0
var _measure_start_usec := 0
var _camera: Camera3D
var _splat: GaussianSplatNode

func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	var world_environment := WorldEnvironment.new()
	world_environment.environment = Environment.new()
	var compositor := Compositor.new()
	compositor.compositor_effects = [COMPOSITOR_EFFECT_SCRIPT.new()]
	world_environment.compositor = compositor
	root.add_child(world_environment)

	_splat = GaussianSplatNode.new()
	_splat.gaussian = load(SPLAT_PATH)
	root.add_child(_splat)

	_camera = Camera3D.new()
	_camera.fov = 70.0
	root.add_child(_camera)

	var aabb := _splat.transform * _splat.gaussian.aabb
	print("splat aabb: ", aabb)
	# Floaters inflate the aabb far beyond the captured subject, so frame the
	# origin (where captures are centered) instead of the aabb center.
	# Nodes aren't inside the tree yet during _initialize, so look_at() would fail.
	_camera.look_at_from_position(CAMERA_OFFSET, Vector3.ZERO)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == WARMUP_FRAMES:
		_measure_start_usec = Time.get_ticks_usec()
	elif _frame == WARMUP_FRAMES + MEASURE_FRAMES:
		var seconds := (Time.get_ticks_usec() - _measure_start_usec) / 1_000_000.0
		print("avg fps over %d frames: %.1f" % [MEASURE_FRAMES, MEASURE_FRAMES / seconds])
		var image := root.get_texture().get_image()
		var path := ProjectSettings.globalize_path("res://tests/render_smoke.png")
		image.save_png(path)
		print("screenshot: ", path)
		return true
	return false

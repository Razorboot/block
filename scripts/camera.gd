extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera_target: Marker3D = $Player/Pivot/CameraTarget
@onready var camera_yaw: Node3D = $CameraYaw
@onready var camera_pitch: Node3D = $CameraYaw/CameraPitch
@onready var camera: Camera3D = $CameraYaw/CameraPitch/Camera3D
@onready var head_camera: Marker3D = $Player/Pivot/HeadCamera
@onready var player_pivot: Node3D = $Player/Pivot

@export var mouse_sensitivity := 0.004
@export var controller_sensitivity := 3.0

@export var min_pitch := deg_to_rad(-75)
@export var max_pitch := deg_to_rad(80)
@export var fp_min_pitch := deg_to_rad(-89)
@export var fp_max_pitch := deg_to_rad(89)

@export var min_zoom := 0.0
@export var max_zoom := 36.0
@export var zoom_speed := 10.0
@export var zoom_smooth := 8.0
@export var scroll_step := 1.2

@export var fp_lock_threshold := 1.5
@export var fp_full_threshold := 0.0

@export var look_offset := Vector3(0, 0, 0)
@export var head_bias_start := 3.0
@export var head_bias_end := 0.0

var yaw := 0.0
var pitch := deg_to_rad(-10)
var zoom := 4.0
var zoom_target := 4.0
var first_person := false
var rotating := false

var _body_meshes: Array[MeshInstance3D] = []
var _body_mats: Array[StandardMaterial3D] = []

func _ready() -> void:
	camera.position = Vector3(0.0, 0.0, zoom)
	_cache_body_meshes()

#TODO: not necessary if the character becomes joined again so it'll have one mat.
func _cache_body_meshes() -> void:
	for node in player_pivot.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var mat := mesh.get_active_material(0)
		if mat:
			var dup := mat.duplicate() as StandardMaterial3D
			dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.set_surface_override_material(0, dup)
			_body_meshes.append(mesh)
			_body_mats.append(dup)

func _set_body_alpha(alpha: float) -> void:
	for mat in _body_mats:
		mat.albedo_color.a = alpha

func _clamp_pitch() -> void:
	if first_person:
		pitch = clamp(pitch, fp_min_pitch, fp_max_pitch)
	else:
		pitch = clamp(pitch, min_pitch, max_pitch)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if not first_person:
			rotating = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if rotating else Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion:
		if rotating or first_person:
			yaw   -= event.relative.x * mouse_sensitivity
			pitch -= event.relative.y * mouse_sensitivity
			_clamp_pitch()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target -= scroll_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target += scroll_step
		zoom_target = clamp(zoom_target, min_zoom, max_zoom)


func _process(delta: float) -> void:
	var yaw_input   := Input.get_action_strength("camera_left")  - Input.get_action_strength("camera_right")
	var pitch_input := Input.get_action_strength("camera_up") - Input.get_action_strength("camera_down")

	if abs(yaw_input)   < 0.1:
		yaw_input   = 0.0
	if abs(pitch_input) < 0.1:
		pitch_input = 0.0
	
	#TODO: THIS WHOLE BUNCH OF BULLSHIT IS HORRIBLE
	# 1: need to remove the fp transition
	# 2: should respect the original yaw/pitch when entering fp mode

	yaw += yaw_input   * controller_sensitivity * delta
	pitch += pitch_input * controller_sensitivity * delta
	_clamp_pitch()

	var zoom_input := Input.get_action_strength("camera_zoom_in") - Input.get_action_strength("camera_zoom_out")
	if zoom_input != 0.0:
		zoom_target -= zoom_input * zoom_speed * delta
		zoom_target  = clamp(zoom_target, min_zoom, max_zoom)

	zoom = lerp(zoom, zoom_target, zoom_smooth * delta)
	first_person = zoom <= fp_full_threshold + 0.5

	var in_fp_zone := zoom_target <= 0.2
	if in_fp_zone or first_person:
		rotating = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif not rotating:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var fade : Variant = clamp(inverse_lerp(fp_lock_threshold, fp_full_threshold + 0.5, zoom), 0.0, 1.0)
	_set_body_alpha(1.0 - fade)

	camera_yaw.global_position = camera_target.global_position
	camera_yaw.rotation.y = yaw
	camera_pitch.rotation.x = pitch
	camera.global_transform.basis = camera_pitch.global_transform.basis
	if first_person:
		player_pivot.rotation.y = yaw
		camera.global_position = head_camera.global_position
		camera.global_transform.basis = camera_pitch.global_transform.basis
	else:
		var bias : Variant = 0
		var focus := (camera_target.global_position + look_offset).lerp(head_camera.global_position, bias)
		var fp_blend : Variant = clamp(inverse_lerp(fp_lock_threshold, fp_full_threshold, zoom), 0.0, 1.0)
		var arm_tip := camera_pitch.global_position + camera_pitch.global_transform.basis.z * zoom

		camera.global_position = arm_tip.lerp(head_camera.global_position, fp_blend)

		var look_dir := focus - camera.global_position

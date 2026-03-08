extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera_yaw: Node3D = $CameraYaw
@onready var camera_pitch: Node3D = $CameraYaw/CameraPitch

@export var min_pitch := deg_to_rad(-60)
@export var max_pitch := deg_to_rad(90)
@export var key_rotate_speed := 2.0
@export var mouse_sensitivity := 0.004

var yaw := 0.0
var pitch := 0.0
var rotating_with_mouse := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		rotating_with_mouse = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if rotating_with_mouse else Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and rotating_with_mouse:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, min_pitch, max_pitch)

func _process(delta: float) -> void:
	camera_yaw.global_position = player.global_position

	if Input.is_action_pressed("camera_left"):
		yaw += key_rotate_speed * delta
	if Input.is_action_pressed("camera_right"):
		yaw -= key_rotate_speed * delta
	if Input.is_action_pressed("camera_up"):
		pitch += key_rotate_speed * delta
	if Input.is_action_pressed("camera_down"):
		pitch -= key_rotate_speed * delta

	pitch = clamp(pitch, min_pitch, max_pitch)

	camera_yaw.rotation.y = yaw
	camera_pitch.rotation.x = pitch

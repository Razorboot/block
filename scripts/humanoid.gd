extends CharacterBody3D

@export var move_speed := 2.5
@export var jump_velocity := 7.5
@export var gravity := 24.0
@export var turn_speed := 6.0

@onready var pivot: Node3D = $Pivot
@onready var camera_pivot: Node3D = $"../CameraYaw"

func _physics_process(delta: float) -> void:
	var input_vec := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_vec.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_vec.x -= 1.0
	if Input.is_action_pressed("move_back"):
		input_vec.y += 1.0
	if Input.is_action_pressed("move_forward"):
		input_vec.y -= 1.0

	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	var cam_forward := camera_pivot.global_transform.basis.z
	var cam_right := camera_pivot.global_transform.basis.x

	cam_forward.y = 0.0
	cam_right.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	# Build movement relative to camera
	var move_dir := cam_right * input_vec.x + cam_forward * input_vec.y

	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	# Turn character to face movement direction
	if move_dir.length() > 0.001:
		var target_basis := Basis.looking_at(move_dir, Vector3.UP)
		pivot.basis = pivot.basis.slerp(target_basis, turn_speed * delta)

	# JUMP....
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	move_and_slide()

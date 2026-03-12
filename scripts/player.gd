extends CharacterBody3D

@export var move_speed := 2.5
@export var jump_velocity := 7.0
@export var gravity := 24.0
@export var turn_speed := 6.0

@onready var pivot: Node3D = $Pivot
@onready var camera_pivot: Node3D = $"../CameraYaw"
@onready var skeleton: Skeleton3D = $Pivot/Character/Armature/Skeleton3D

enum AnimState { IDLE, WALK }
var anim_state := AnimState.IDLE

var r_leg: int
var l_leg: int
var r_arm: int
var l_arm: int

var base_pose := {}
var walk_time := 0.0
var prev_walk_angle := 0.0
var finishing_walk := false
var jump_blend := 0.0

var jump_initialized := false
var start_r_arm_rot: Vector3
var start_l_arm_rot: Vector3

const WALK_FREQ := 7.5
const WALK_AMPLITUDE := 0.7
const IDLE_FREQ := 0.8
const IDLE_AMPLITUDE := 0.1
const JUMP_BLEND_SPEED := 6.0

func _ready():
	r_leg = skeleton.find_bone("RLeg_BONE")
	l_leg = skeleton.find_bone("LLeg_BONE")
	r_arm = skeleton.find_bone("RArm_BONE")
	l_arm = skeleton.find_bone("LArm_BONE")

	for bone in [r_leg, l_leg, r_arm, l_arm]:
		base_pose[bone] = skeleton.get_bone_pose_rotation(bone)


func _physics_process(delta):
	handle_movement(delta)
	var moving = velocity.length() > 0.1
	update_animation_state(moving)
	
	if is_on_floor():
		walk_time += delta
	else:
		walk_time = 0.0

	update_animation(delta)

func handle_movement(delta):
	var input_vec := Vector2.ZERO
	if Input.is_action_pressed("move_right"):  input_vec.x += 1
	if Input.is_action_pressed("move_left"):   input_vec.x -= 1
	if Input.is_action_pressed("move_back"):   input_vec.y += 1
	if Input.is_action_pressed("move_forward"): input_vec.y -= 1
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	var cam_forward := camera_pivot.global_transform.basis.z
	var cam_right := camera_pivot.global_transform.basis.x
	cam_forward.y = 0.0
	cam_right.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var move_dir := cam_right * input_vec.x + cam_forward * input_vec.y
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if move_dir.length() > 0.001:
		var target_basis := Basis.looking_at(move_dir, Vector3.UP)
		pivot.basis = pivot.basis.slerp(target_basis, turn_speed * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()


func update_animation_state(moving: bool):
	if moving:
		anim_state = AnimState.WALK
		finishing_walk = false
	elif anim_state == AnimState.WALK:
		finishing_walk = true
	else:
		anim_state = AnimState.IDLE


func update_animation(delta: float):
	jump_blend = move_toward(jump_blend, 0.0 if is_on_floor() else 1.0, delta * JUMP_BLEND_SPEED)

	match anim_state:
		AnimState.WALK: animate_walk(walk_time)
		AnimState.IDLE: animate_idle(walk_time)

	if jump_blend > 0.0:
		apply_jump_overlay()


func animate_walk(time: float):
	var angle := WALK_AMPLITUDE * sin(time * WALK_FREQ)

	if finishing_walk:
		if sign(prev_walk_angle) != sign(angle):
			finishing_walk = false
			anim_state = AnimState.IDLE
			animate_idle(time)
			prev_walk_angle = angle
			return

	prev_walk_angle = angle

	if jump_blend > 0.0:
		return

	skeleton.set_bone_pose_rotation(r_arm, base_pose[r_arm] * Quaternion(Vector3.LEFT, -angle))
	skeleton.set_bone_pose_rotation(l_arm, base_pose[l_arm] * Quaternion(Vector3.RIGHT, -angle))
	skeleton.set_bone_pose_rotation(r_leg, base_pose[r_leg] * Quaternion(Vector3.FORWARD, -angle))
	skeleton.set_bone_pose_rotation(l_leg, base_pose[l_leg] * Quaternion(Vector3.FORWARD, -angle))


func animate_idle(time: float):
	var angle := IDLE_AMPLITUDE * sin(time * IDLE_FREQ)

	if jump_blend > 0.0:
		return

	skeleton.set_bone_pose_rotation(r_arm, base_pose[r_arm] * Quaternion(Vector3.LEFT, -angle))
	skeleton.set_bone_pose_rotation(l_arm, base_pose[l_arm] * Quaternion(Vector3.RIGHT, -angle))
	skeleton.set_bone_pose_rotation(r_leg, base_pose[r_leg] * Quaternion(Vector3.FORWARD, -angle))
	skeleton.set_bone_pose_rotation(l_leg, base_pose[l_leg] * Quaternion(Vector3.FORWARD, -angle))


func apply_jump_overlay():
	if not jump_initialized:
		start_r_arm_rot = skeleton.get_bone_pose(r_arm).basis.get_euler()
		start_l_arm_rot = skeleton.get_bone_pose(l_arm).basis.get_euler()
		jump_initialized = true

	var target_r := start_r_arm_rot + Vector3(PI, 0, 0)
	var target_l := start_l_arm_rot + Vector3(PI, 0, 0)

	var r_pose := skeleton.get_bone_pose(r_arm)
	r_pose.basis = Basis.from_euler(start_r_arm_rot.lerp(target_r, jump_blend))
	skeleton.set_bone_pose_rotation(r_arm, r_pose.basis.get_rotation_quaternion())

	var l_pose := skeleton.get_bone_pose(l_arm)
	l_pose.basis = Basis.from_euler(start_l_arm_rot.lerp(target_l, jump_blend))
	skeleton.set_bone_pose_rotation(l_arm, l_pose.basis.get_rotation_quaternion())

	skeleton.set_bone_pose_rotation(r_leg, skeleton.get_bone_pose_rotation(r_leg).slerp(base_pose[r_leg], jump_blend))
	skeleton.set_bone_pose_rotation(l_leg, skeleton.get_bone_pose_rotation(l_leg).slerp(base_pose[l_leg], jump_blend))

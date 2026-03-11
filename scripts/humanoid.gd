extends CharacterBody3D

@export var move_speed := 2.5
@export var jump_velocity := 7.5
@export var gravity := 24.0
@export var turn_speed := 6.0

@onready var pivot: Node3D = $Pivot
@onready var camera_pivot: Node3D = $"../CameraYaw"
@onready var skeleton: Skeleton3D = $Pivot/Character/Armature/Skeleton3D

enum AnimState { IDLE, WALK } # JUMP
var anim_state : AnimState = AnimState.IDLE

var r_leg
var l_leg
var r_arm
var l_arm
var head

var jump_blend := 0.0
var base_pose = {}
var prev_walk_angle := 0.0
var finishing_walk := false

const STEP_RATE := 0.1
const WALK_FREQ := 9.0
const WALK_AMPLITUDE := 0.5
const IDLE_FREQ := 0.8
const IDLE_AMPLITUDE := 0.1
const JUMP_BLEND_SPEED := 6.0

func _ready():
	r_leg = skeleton.find_bone("RLeg_BONE")
	l_leg = skeleton.find_bone("LLeg_BONE")
	r_arm = skeleton.find_bone("RArm_BONE")
	l_arm = skeleton.find_bone("LArm_BONE")
	head = skeleton.find_bone("Head_BONE")

	base_pose[r_leg] = skeleton.get_bone_pose_rotation(r_leg)
	base_pose[l_leg] = skeleton.get_bone_pose_rotation(l_leg)
	base_pose[r_arm] = skeleton.get_bone_pose_rotation(r_arm)
	base_pose[l_arm] = skeleton.get_bone_pose_rotation(l_arm)


func _physics_process(delta):
	handle_movement(delta)
	var moving = velocity.length() > 0.1
	update_animation_state(moving)
	update_animation(delta)


func handle_movement(delta):
	var input_vec := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_vec.x += 1
	if Input.is_action_pressed("move_left"):
		input_vec.x -= 1
	if Input.is_action_pressed("move_back"):
		input_vec.y += 1
	if Input.is_action_pressed("move_forward"):
		input_vec.y -= 1

	if input_vec.length() > 1:
		input_vec = input_vec.normalized()

	var cam_forward = camera_pivot.global_transform.basis.z
	var cam_right = camera_pivot.global_transform.basis.x

	cam_forward.y = 0
	cam_right.y = 0

	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var move_dir = cam_right * input_vec.x + cam_forward * input_vec.y

	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if move_dir.length() > 0.001:
		var target_basis = Basis.looking_at(move_dir, Vector3.UP)
		pivot.basis = pivot.basis.slerp(target_basis, turn_speed * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()


func update_animation_state(moving):
	if moving:
		anim_state = AnimState.WALK
		finishing_walk = false
	else:
		if anim_state == AnimState.WALK:
			finishing_walk = true
		else:
			anim_state = AnimState.IDLE


func update_animation(delta):
	if not is_on_floor():
		jump_blend = min(jump_blend + delta * JUMP_BLEND_SPEED, 1.0)
	else:
		jump_blend = max(jump_blend - delta * JUMP_BLEND_SPEED, 0.0)

	var time = Time.get_ticks_msec() * 0.001

	match anim_state:
		AnimState.WALK:
			animate_walk(time)

		AnimState.IDLE:
			animate_idle(time)

	if jump_blend > 0.0:
		apply_jump_overlay()


func animate_walk(time):
	var angle = WALK_AMPLITUDE * sin(time * WALK_FREQ)
	
	if finishing_walk:
		if sign(prev_walk_angle) != sign(angle):
			finishing_walk = false
			anim_state = AnimState.IDLE
			animate_idle(time)
			prev_walk_angle = angle
			return

	if jump_blend == 0.0:
		var r_arm_rot = Quaternion(Vector3.LEFT, -angle)
		var l_arm_rot = Quaternion(Vector3.RIGHT, -angle)
		skeleton.set_bone_pose_rotation(r_arm, base_pose[r_arm] * r_arm_rot)
		skeleton.set_bone_pose_rotation(l_arm, base_pose[l_arm] * l_arm_rot)

		var r_leg_rot = Quaternion(Vector3.FORWARD, -angle)
		var l_leg_rot = Quaternion(Vector3.FORWARD, -angle)
		skeleton.set_bone_pose_rotation(r_leg, base_pose[r_leg] * r_leg_rot)
		skeleton.set_bone_pose_rotation(l_leg, base_pose[l_leg] * l_leg_rot)

	prev_walk_angle = angle

func animate_idle(time):
	var angle = IDLE_AMPLITUDE * sin(time * IDLE_FREQ)

	if jump_blend == 0.0:
		var r_arm_rot = Quaternion(Vector3.LEFT, -angle)
		var l_arm_rot = Quaternion(Vector3.RIGHT, -angle)
		skeleton.set_bone_pose_rotation(r_arm, base_pose[r_arm] * r_arm_rot)
		skeleton.set_bone_pose_rotation(l_arm, base_pose[l_arm] * l_arm_rot)

		var r_leg_rot = Quaternion(Vector3.FORWARD, -angle)
		var l_leg_rot = Quaternion(Vector3.FORWARD, -angle)
		skeleton.set_bone_pose_rotation(r_leg, base_pose[r_leg] * r_leg_rot)
		skeleton.set_bone_pose_rotation(l_leg, base_pose[l_leg] * l_leg_rot)
	
var start_r_arm_rot
var start_l_arm_rot
var jump_initialized = false

func apply_jump_overlay():
	if !jump_initialized:
		start_r_arm_rot = skeleton.get_bone_pose(r_arm).basis.get_euler()
		start_l_arm_rot = skeleton.get_bone_pose(l_arm).basis.get_euler()
		jump_initialized = true
	
	var target_r = start_r_arm_rot
	target_r.x += PI
	
	var target_l = start_l_arm_rot
	target_l.x += PI
	
	var r = start_r_arm_rot.lerp(target_r, jump_blend)
	var l = start_l_arm_rot.lerp(target_l, jump_blend)
	
	var pose = skeleton.get_bone_pose(r_arm)
	pose.basis = Basis.from_euler(r)
	
	var Lpose = skeleton.get_bone_pose(l_arm)
	Lpose.basis = Basis.from_euler(l)
	skeleton.set_bone_pose_rotation(r_arm, pose.basis.get_rotation_quaternion())
	skeleton.set_bone_pose_rotation(l_arm, Lpose.basis.get_rotation_quaternion())

	var current_r_leg = skeleton.get_bone_pose_rotation(r_leg)
	var current_l_leg = skeleton.get_bone_pose_rotation(l_leg)
	skeleton.set_bone_pose_rotation(r_leg, current_r_leg.slerp(base_pose[r_leg], jump_blend))
	skeleton.set_bone_pose_rotation(l_leg, current_l_leg.slerp(base_pose[l_leg], jump_blend))

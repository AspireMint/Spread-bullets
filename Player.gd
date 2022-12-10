extends KinematicBody

# Controls:
# Pause/Resume:		Esc
# Moving: 			W S A D
# Jump:				Space
# Run/Fly fast:		E
# Toggle fly mode: 	F
# Fly up:			Space
# Fly down:			Shift

export var speed = 14
export var fall_acceleration = 75

export var jump_strength = 15
export var mouse_sensitivity = 0.5

var velocity = Vector3.ZERO

var fly = true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if can_move():
		move(delta)

func move(delta) -> void:
	var direction = Vector3.ZERO

	if Input.is_action_pressed("right"):
		direction += transform.basis.x
	if Input.is_action_pressed("left"):
		direction += -transform.basis.x
	if Input.is_action_pressed("backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("forward"):
		direction += -transform.basis.z
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
	
	# Vertical velocity
	if is_on_floor():
		if Input.is_action_pressed("up"):
			velocity.y = jump_strength
		else:
			velocity.y = 0
	else:
		velocity.y -= fall_acceleration * delta
		velocity.y = clamp(velocity.y, -fall_acceleration, jump_strength)
	
	# Ground velocity
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	if Input.is_action_just_pressed("fly"):
		fly = not fly
	
	if fly:
		velocity.y = 0
		if Input.is_action_pressed("up"):
			transform.origin.y = transform.origin.y + speed * delta
		if Input.is_action_pressed("down"):
			transform.origin.y = transform.origin.y - speed * delta
	
	if Input.is_action_pressed("run"):
		speed = speed * 1.1
		speed = clamp(speed, 14, 14*50)
	else:
		speed = 14

	move_and_slide(velocity, Vector3.UP, true)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if can_move():
		aim(event)
		click(event)

func can_move() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func aim(event) -> void:
	var mouse_motion = event as InputEventMouseMotion
	if mouse_motion:
		rotation_degrees.y -= mouse_motion.relative.x * mouse_sensitivity
		var current_tilt = $Camera.rotation_degrees.x
		current_tilt -= mouse_motion.relative.y * mouse_sensitivity
		$Camera.rotation_degrees.x = clamp(current_tilt, -90, 90)

func click(event):
	var event_mouse_button = event as InputEventMouseButton
	if event_mouse_button && event_mouse_button.pressed and event_mouse_button.button_index==BUTTON_LEFT:
		var bullet_range = 1000
		var bullet_spread = 0.1
		
		var space_state = get_world().get_direct_space_state()
		var from = $Camera.project_ray_origin(event_mouse_button.position)
		var dir = $Camera.project_ray_normal(event_mouse_button.position)
		var spread = dir.rotated(Vector3.UP, rand_range(0, bullet_spread))
		var bullet_dir = spread.rotated(dir, rand_range(0, TAU))
		var to = bullet_dir * bullet_range
		
		var exclude_list = []
		for b in Globals.bullets_list.get_children():
			exclude_list.append(b.get_child(0))
		
		var result = space_state.intersect_ray(from, to, exclude_list)
		if not result.has("position"):
			return
		
		var hit_pos = result.position
		var bullet: Spatial = Globals.bullet.duplicate()
		bullet.transform.origin = hit_pos
		Globals.bullets_list.add_child(bullet)

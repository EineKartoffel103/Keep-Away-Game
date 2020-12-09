extends KinematicBody

onready var head = $Head
onready var attack_ray = $Head/AttackRay
onready var attack_windup = $AttackWindup
onready var attack_cooldown = $AttackCooldown

onready var sound_swoosh = $Sounds/Swoosh
onready var sound_clang = $Sounds/Clang
onready var sound_ow = $Sounds/Ow
onready var sound_hitworld = $Sounds/HitWorld

# settings
export var controlling_player: int = 0
export var look_sensitivity = 0.5
var look_device = InputEventMouseMotion # todo: test with Joypads

# combat statistics
var push_strength = 8
var attack_windup_time = 0.1
var attack_cooldown_time = 0.4

# movement statistics
var speed = 5
var h_acceleration = 10
var gravity = 13
var jump = 6

# character controller vars
var movement = Vector3()
var direction = Vector3()
var velocity = Vector3()
var h_velocity = Vector3()
var gravity_vec = Vector3()
var translate_offset = Vector3()
var camera_height = 0.5

# movement checks
var movement_enabled = true
var attacking = false

func _ready():
	translate_offset = Vector3(0,camera_height,0)
	attack_windup.wait_time = attack_windup_time
	attack_cooldown.wait_time = attack_cooldown_time

func _on_AttackWindup_timeout():
	if attack_cooldown.is_stopped():
		attacking = true
		yield(get_tree(),"idle_frame")
		attacking = false
		attack_cooldown.start()

func _input(event):
	if event is look_device and movement_enabled: # todo: test with Joypads
		rotate_y(deg2rad(-event.relative.x * look_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * look_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))
	if attack_cooldown.is_stopped() and attack_windup.is_stopped():
		if event.is_action_pressed("attack_%s" % [controlling_player]):
			attack_windup.start()
			sound_swoosh.play()

func _physics_process(delta):
	direction = Vector3()
	
	# jumping and falling
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
	else:
		gravity_vec = Vector3.ZERO
	if Input.is_action_pressed("jump_%s" % [controlling_player]) and is_on_floor() and movement_enabled:
		gravity_vec = Vector3.UP * jump
	
	# walking
	if Input.is_action_pressed("fwd_%s" % [controlling_player]):
		direction -= transform.basis.z
	if Input.is_action_pressed("back_%s" % [controlling_player]):
		direction += transform.basis.z
	if Input.is_action_pressed("left_%s" % [controlling_player]):
		direction -= transform.basis.x
	if Input.is_action_pressed("right_%s" % [controlling_player]):
		direction += transform.basis.x
	if movement_enabled:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO
	# applying force from attacks
	if attacking:
		var look_direction = Vector3(0,head.rotation.x,0) - transform.basis.z # get all angles
		look_direction.y += 1.15 # hit items off the ground for cartoony effect
		look_direction *= push_strength
		var reported_body = attack_ray.get_collider()
		if reported_body != null:
			var impact_type = reported_body.get_class()
			print(impact_type)
			match impact_type:
				"RigidBody": # physics object
					reported_body.apply_impulse(Vector3.ZERO,look_direction)
				"KinematicBody": # player
					reported_body.gravity_vec += look_direction
					# bad code:
					#reported_body.move_and_collide(Vector3(look_direction.x,0,look_direction.z))
					# fixed with:
					#reported_body.gravity_vec += look_direction
			play_impact_sound(impact_type)
	# momentum
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
	# final calculations
	movement.z = h_velocity.z + gravity_vec.z
	movement.x = h_velocity.x + gravity_vec.x
	movement.y = gravity_vec.y
	move_and_slide(movement, Vector3.UP)

func _on_Grabber_body_entered(body):
	print(body)

func play_impact_sound(impact_type:String):
	var random_pitch = rand_range(0.8,1.2)
	match impact_type:
		"KinematicBody":
			sound_clang.pitch_scale = random_pitch
			sound_ow.pitch_scale = random_pitch
			sound_clang.play()
			sound_ow.play()
		"RigidBody":
			sound_clang.pitch_scale = random_pitch
			sound_clang.play()
		"StaticBody":
			sound_hitworld.pitch_scale = random_pitch
			sound_hitworld.play()
		"CSGCombiner":
			sound_hitworld.pitch_scale = random_pitch
			sound_hitworld.play()

#func die():
#	speed = 0
#	camera_height = -0.55
#	translate_offset = Vector3(0,camera_height,0)
#
#func live():
#	speed = 5
#	camera_height = 0.55
#	translate_offset = Vector3(0,camera_height,0)
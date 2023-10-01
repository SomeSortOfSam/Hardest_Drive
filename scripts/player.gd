extends CharacterBody2D

const SPEED = 300.0

@export var drone_track : AudioStream
@export var droneless_track : AudioStream

@onready var chain : Line2D = $Line2D
@onready var sprite : Node2D = $Rotor
@onready var move_animator :AnimationPlayer = $MoveAnimator
@onready var anim_sprite :AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast : RayCast2D = $RayCast2D
@onready var walk_dust : GPUParticles2D = $WalkDust
@onready var shoot_animator :AnimationPlayer = $ShootAnimator
@onready var harpoon_hit :GPUParticles2D = $HarpoonHit
@onready var hurt_warn :GPUParticles2D = $HurtWarn
@onready var audio : AudioStreamPlayer = $AudioStreamPlayer

var harpoon_tween : Tween
var rotate_tween : Tween
var harpoon_direction : float
var harpoon_target : CollisionObject2D

signal pull_requested(direction : float)

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var horizontal_input = Input.get_axis("player_left", "player_right")
	var vertical_input = Input.get_axis("player_up", "player_down")
	if horizontal_input:
		velocity.x = horizontal_input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if vertical_input:
		velocity.y = vertical_input * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	if velocity.length() > 0:
		walk_dust.emitting = true
		move_animator.play("WalkBounce")
	else:
		walk_dust.emitting = false
		move_animator.play("Idle")
	
	if velocity.x > 0:
		anim_sprite.scale = Vector2(-1,1)
	else:
		anim_sprite.scale = Vector2(1,1)
	
	
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var angle_to_mouse = get_global_mouse_position().angle_to_point(global_position) - PI/2
		var target_rotation : float = snapped(angle_to_mouse,PI/2)
		if !is_equal_approx(sprite.rotation,target_rotation) and !rotate_tween and !harpoon_tween:
			start_rotation_tween(target_rotation)
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_fire_harpoon()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			stop_harpoon()
	if event.is_action("reset_screen"):
		stop_harpoon()
		shoot_animator.play("SpaceHit")

func start_rotation_tween(target_rotation : float):
	if rotate_tween:
		rotate_tween.quit()
	rotate_tween = create_tween()
	var old_rotation = sprite.rotation
	rotate_tween.tween_method(func(percent : float): sprite.rotation = lerp_angle(old_rotation,target_rotation,percent),0.0,1.0,0.1)
	rotate_tween.parallel()
	rotate_tween.tween_method(func(percent : float): ray_cast.rotation = lerp_angle(old_rotation,target_rotation,percent),0.0,1.0,0.1)
	rotate_tween.tween_callback(func():rotate_tween = null)
	rotate_tween.set_trans(Tween.TRANS_BOUNCE)

func try_fire_harpoon():
	if !harpoon_tween:
		fire_harpoon()
	else:
		pull_harpoon()

func fire_harpoon():
	var playback_position = audio.get_playback_position()
	audio.stream = drone_track
	audio.play(playback_position)
	var target = ray_cast.get_collision_point()
	harpoon_tween = create_tween()
	harpoon_tween.tween_method(func(percent : float): chain.points[0] = lerp(Vector2.ZERO,to_local(target), percent),0,1,.15)
	harpoon_tween.tween_callback(add_hit_fx)
	harpoon_tween.tween_callback(while_harpoon_out.bind(target))
	harpoon_direction = sprite.rotation
	shoot_animator.play("HarpoonOut")
	if ray_cast.get_collider() and ray_cast.get_collider().has_method("_on_player_pull_requested"):
		harpoon_target = ray_cast.get_collider()
		pull_requested.connect(harpoon_target._on_player_pull_requested)

func pull_harpoon():
	pull_requested.emit(harpoon_direction)
	var rotation = harpoon_direction
	if rotation < 0:
		rotation = TAU + rotation
	rotation = fmod(rotation + (PI/2),TAU)
	rotation = deg_to_rad(round(rad_to_deg(rotation)))
	var transition := Vector2(cos(rotation), sin(rotation))
	transition *= Vector2(get_parent().tile_set.tile_size)
	var current = to_global(chain.points[0])
	var target = to_global(chain.points[0]) + transition
	harpoon_tween.kill()
	harpoon_tween = create_tween()
	harpoon_tween.tween_method(func(percent : float): chain.points[0] = \
	lerp(to_local(current),to_local(target),percent),0.0,1.0,.5).set_trans(Tween.TRANS_ELASTIC)
	harpoon_tween.tween_callback(while_harpoon_out.bind(target))
	shoot_animator.play("Pull")

func add_hit_fx():
	harpoon_hit.position = chain.points[0]
	harpoon_hit.rotation = sprite.rotation
	harpoon_hit.emitting = true

func while_harpoon_out(target):
	if harpoon_tween:
		harpoon_tween.kill()
	harpoon_tween = create_tween()
	harpoon_tween.tween_callback(func(): sprite.rotation = target.angle_to_point(global_position) - PI/2)
	harpoon_tween.tween_callback(func(): chain.points[0] = to_local(target))
	harpoon_tween.tween_interval(.01)
	harpoon_tween.set_loops()

func stop_harpoon():
	if harpoon_tween:
		var playback_position = audio.get_playback_position()
		audio.stream = droneless_track
		audio.play(playback_position)
		if harpoon_target and pull_requested.is_connected(harpoon_target._on_player_pull_requested):
			pull_requested.disconnect(harpoon_target._on_player_pull_requested)
		harpoon_tween.kill()
		harpoon_tween = create_tween()
		harpoon_tween.tween_method(func(vec : Vector2): chain.points[0] = vec,chain.points[1],Vector2.ZERO,.1)
		harpoon_tween.tween_callback(func(): harpoon_tween = null)
		shoot_animator.play("HarpoonIn")
		var angle_to_mouse = get_global_mouse_position().angle_to_point(global_position) - PI/2
		var target_rotation : float = snapped(angle_to_mouse,PI/2)
		harpoon_tween.tween_callback(start_rotation_tween.bind(target_rotation))

func _on_hit_box_area_entered(area : Area2D):
	velocity += (global_position - area.global_position).normalized() * SPEED * 10
	hurt_warn.emitting = true

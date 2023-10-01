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
@onready var hurt_hit :GPUParticles2D = $HurtHit
@onready var audio : AudioStreamPlayer = $AudioStreamPlayer
@onready var hurt_audio : AudioStreamPlayer2D = $HurtSound
@onready var tile_map_checker : Area2D = $Node2D/TileMapCheck

var harpoon_tween : Tween
var rotate_tween : Tween
var harpoon_direction : float
var harpoon_target : CollisionObject2D
var is_overlaping_tilemap := false
var can_reset_screen := false
var can_move := false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_safe_position : Vector2

signal pull_requested(direction : float)

func get_movement_input():
	var horizontal_input = Input.get_axis("player_left", "player_right")
	var vertical_input = Input.get_axis("player_up", "player_down")
	if horizontal_input:
		velocity.x = horizontal_input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if vertical_input:
		velocity.y = vertical_input * SPEED
	elif is_overlaping_tilemap:
		velocity.y = move_toward(velocity.y, 0, SPEED)

func _physics_process(delta):
	if can_move:
		get_movement_input()
	
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
	
	
	tile_map_checker.position = velocity*delta
	if can_move and !is_overlaping_tilemap:
		if position == last_safe_position:
			velocity.y += gravity * delta
			move_and_slide()
			last_safe_position = position
		else:
			velocity = Vector2.ZERO
			position = last_safe_position
	elif move_and_slide():
		ray_cast.set_collision_mask_value(1,true)
		set_collision_mask_value(2,true)

	
	
	if is_overlaping_tilemap:
		last_safe_position = position

func get_target_rotation() -> float:
	var angle_to_mouse = get_global_mouse_position().angle_to_point(global_position) - PI/2
	return snapped(angle_to_mouse,PI/2)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if !is_equal_approx(sprite.rotation,get_target_rotation()) and !rotate_tween and !harpoon_tween:
			start_rotation_tween(get_target_rotation())
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_fire_harpoon()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			stop_harpoon()
	if can_reset_screen and event.is_action("reset_screen"):
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

func create_fire_harpoon_tween():
	var target = ray_cast.get_collision_point()
	harpoon_tween = create_tween()
	harpoon_tween.tween_method(func(percent : float): chain.points[0] = lerp(Vector2.ZERO,to_local(target), percent),0,1,.15)
	harpoon_tween.tween_callback(add_hit_fx)
	harpoon_tween.tween_callback(while_harpoon_out.bind(target))

func switch_track(new_track : AudioStream):
	var playback_position = audio.get_playback_position()
	audio.stream = new_track
	audio.play(playback_position)

func fire_harpoon():
	switch_track(drone_track)
	create_fire_harpoon_tween()
	harpoon_direction = sprite.rotation
	shoot_animator.play("HarpoonOut")
	if ray_cast.get_collider():
		harpoon_target = null
		print(ray_cast.get_collider())
		if ray_cast.get_collider().has_method("_on_player_pull_requested"):
			harpoon_target = ray_cast.get_collider()
			pull_requested.connect(harpoon_target._on_player_pull_requested)

func rotation_to_direction(the_roatation : float) -> Vector2:
	if the_roatation < 0:
		the_roatation = TAU + the_roatation
	the_roatation = fmod(the_roatation + (PI/2),TAU)
	the_roatation = deg_to_rad(round(rad_to_deg(the_roatation)))
	return Vector2(cos(the_roatation), sin(the_roatation))

func create_pull_harpoon_tween():
	var transition = rotation_to_direction(harpoon_direction) * Vector2(get_parent().tile_set.tile_size)
	var current = to_global(chain.points[0])
	var target = to_global(chain.points[0]) + transition
	harpoon_tween.kill()
	harpoon_tween = create_tween()
	harpoon_tween.tween_method(func(percent : float): chain.points[0] = \
	lerp(to_local(current),to_local(target),percent),0.0,1.0,.5).set_trans(Tween.TRANS_ELASTIC)
	harpoon_tween.tween_callback(while_harpoon_out.bind(target))

func create_pulled_by_harpoon_tween():
	velocity += to_local( ray_cast.get_collision_point()) * SPEED
	stop_harpoon()

func pull_harpoon():
	if harpoon_target:
		create_pull_harpoon_tween()
	else:
		create_pulled_by_harpoon_tween()
	shoot_animator.play("Pull")
	pull_requested.emit(harpoon_direction)

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

func create_stop_harpoon_tween():
	harpoon_tween.kill()
	harpoon_tween = create_tween()
	harpoon_tween.tween_method(func(vec : Vector2): chain.points[0] = vec,chain.points[1],Vector2.ZERO,.1)
	harpoon_tween.tween_callback(func(): harpoon_tween = null)

func stop_harpoon():
	if !harpoon_tween:
		return

	switch_track(droneless_track)
	if harpoon_target and pull_requested.is_connected(harpoon_target._on_player_pull_requested):
		pull_requested.disconnect(harpoon_target._on_player_pull_requested)
	create_stop_harpoon_tween()
	shoot_animator.play("HarpoonIn")
	harpoon_tween.tween_callback(start_rotation_tween.bind(get_target_rotation()))

func _on_hit_box_area_entered(area : Area2D):
	velocity += (global_position - area.global_position).normalized() * SPEED * 10
	hurt_warn.emitting = true
	hurt_hit.emitting = true
	hurt_audio.play()

func _on_tile_map_check_body_entered(_body):
	is_overlaping_tilemap = true
	velocity.y = 0

func _on_tile_map_check_body_exited(_body):
	is_overlaping_tilemap = false

func _on_visible_on_screen_notifier_2d_screen_exited():
	if can_move:
		global_position = get_viewport().get_camera_2d().global_position
		printerr("Player out of bounds - reseting")
		var camera = get_viewport().get_camera_2d()
		global_position = camera.global_position + (get_viewport_rect().size * get_viewport_transform().get_scale())/2
		velocity = Vector2.ZERO

func _on_tutorial_player_movement_enabled():
	can_move = true

func _on_tutorial_player_reset_screen_enabled():
	can_reset_screen = true

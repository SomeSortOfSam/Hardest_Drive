extends CharacterBody2D

const SPEED = 300.0

@onready var chain : Line2D = $Line2D
@onready var sprite : Node2D = $Rotor
@onready var move_animator :AnimationPlayer = $MoveAnimator
@onready var respawn_animator :AnimationPlayer = $RespawnAnimator
@onready var anim_sprite :AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast : RayCast2D = $RayCast2D
@onready var walk_dust : GPUParticles2D = $WalkDust
@onready var shoot_animator :AnimationPlayer = $ShootAnimator
@onready var harpoon_hit :GPUParticles2D = $HarpoonHit
@onready var hurt_warn :GPUParticles2D = $HurtWarn
@onready var tele_warn :GPUParticles2D = $TeleportWarning
@onready var hurt_hit :GPUParticles2D = $HurtHit

@onready var hurt_audio : AudioStreamPlayer2D = $HurtSound
@onready var harpoon_shoot_audio : AudioStreamPlayer2D = $HarpoonFireSound
@onready var harpoon_hit_audio : AudioStreamPlayer2D = $HarpoonHitSound
@onready var harpoon_pull_audio : AudioStreamPlayer2D = $HarpoonPullSound
@onready var screen_reset_audio : AudioStreamPlayer2D = $ScreenResetSound
@onready var walk_audio : AudioStreamPlayer2D = $WalkSound

@onready var tile_map_checker : Area2D = $Node2D/TileMapCheck
@onready var timer :Timer = $Timer
@onready var hurt_timer : Timer = $Node2D/HurtTimer
@onready var hit_box : Area2D = $HitBox

var harpoon_tween : Tween
var rotate_tween : Tween
var harpoon_direction : float
var harpoon_target : CollisionObject2D
var is_overlaping_tilemap := false
var can_reset_screen := false
var pullable := false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var moving_enabled := false
var last_safe_position : Vector2
var pull_succsedded := true

signal pull_requested(direction : float, player)
signal reset_position_requested
signal screen_reset

func get_movement_input():
	var horizontal_input = Input.get_axis("player_left", "player_right")
	var vertical_input = Input.get_axis("player_up", "player_down")
	if horizontal_input:
		velocity.x = horizontal_input * SPEED
	elif moving_enabled:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if vertical_input:
		velocity.y = vertical_input * SPEED
	elif moving_enabled:
		velocity.y = move_toward(velocity.y, 0, SPEED)

func _physics_process(delta):
	if moving_enabled:
		get_movement_input()
		animate_character()
	move_and_slide()

func animate_character():
	if velocity.length() > 0:
		walk_dust.emitting = true
		move_animator.play("WalkBounce")
		if !walk_audio.playing:
			var tween = create_tween()
			tween.tween_callback(walk_audio.play)
			tween.tween_property(walk_audio,"volume_db",0.0,.2).set_ease(Tween.EASE_IN)
	else:
		walk_dust.emitting = false
		move_animator.play("Idle")
		if walk_audio.playing:
			var tween = create_tween()
			tween.tween_property(walk_audio,"volume_db",-20.0,.2).set_ease(Tween.EASE_OUT)
			tween.tween_callback(walk_audio.stop)
	
	if velocity.x > 0:
		anim_sprite.scale = Vector2(-1,1)
	elif velocity.length() > 0:
		anim_sprite.scale = Vector2(1,1)

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
	if can_reset_screen and event.is_action_pressed("reset_screen"):
		stop_harpoon()
		shoot_animator.play("SpaceHit")
		screen_reset.emit()
		screen_reset_audio.play()

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
	if ray_cast.get_collider().has_method("_on_player_harpoon_hit"):
		harpoon_tween.tween_callback(ray_cast.get_collider()._on_player_harpoon_hit.bind(self))
	harpoon_tween.tween_callback(harpoon_hit_audio.play)
	harpoon_tween.tween_callback(while_harpoon_out.bind(target))

func fire_harpoon():
	create_fire_harpoon_tween()
	harpoon_direction = sprite.rotation
	shoot_animator.play("HarpoonOut")
	harpoon_shoot_audio.play()
	if ray_cast.get_collider():
		harpoon_target = null
		pullable = false
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
	harpoon_tween.tween_callback(harpoon_pull_audio.play)
	harpoon_tween.tween_method(func(percent : float): chain.points[0] = \
	lerp(to_local(current),to_local(target),percent),0.0,1.0,.5).set_trans(Tween.TRANS_ELASTIC)
	harpoon_tween.tween_callback(while_harpoon_out.bind(target))

func create_pulled_by_harpoon_tween():
	harpoon_pull_audio.play()
	moving_enabled = false
	timer.start(0.3)
	set_collision_mask_value(2,false)
	hit_box.set_collision_mask_value(3,false)
	hit_box.set_collision_layer_value(4,false)
	hit_box.set_collision_layer_value(3,true)
	velocity += chain.points[0] * 4
	await timer.timeout
	moving_enabled = true
	set_collision_mask_value(2,true)
	hit_box.set_collision_mask_value(3,true)
	hit_box.set_collision_layer_value(4,true)
	hit_box.set_collision_layer_value(3,false)
	stop_harpoon()

func pull_harpoon():
	pull_requested.emit(harpoon_direction, self)
	if pull_succsedded:
		if pullable:
			create_pull_harpoon_tween()
		else:
			create_pulled_by_harpoon_tween()
		shoot_animator.play("Pull")
	pull_succsedded = true

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
	harpoon_tween.tween_method(func(vec : Vector2): chain.points[0] = vec,chain.points[1],Vector2(0,10),.1)
	harpoon_tween.tween_callback(func(): harpoon_tween = null)

func stop_harpoon():
	if !harpoon_tween:
		return

	create_stop_harpoon_tween()
	shoot_animator.play("HarpoonIn")
	harpoon_tween.tween_callback(start_rotation_tween.bind(get_target_rotation()))
	if harpoon_target != null and not harpoon_target.is_queued_for_deletion() and\
	pull_requested.is_connected(harpoon_target._on_player_pull_requested):
		pull_requested.disconnect(harpoon_target._on_player_pull_requested)

func _on_hit_box_area_entered(area : Area2D):
	velocity += (global_position - area.global_position).normalized() * SPEED * 10
	hurt_warn.emitting = true
	hurt_hit.emitting = true
	hurt_audio.play()

func _on_tile_map_check_body_entered(_body):
	if moving_enabled:
		set_collision_mask_value(2,true)
	hurt_timer.stop()
	tele_warn.emitting = false

func _on_tile_map_check_body_exited(_body):
	if moving_enabled:
		set_collision_mask_value(2,false)
	hurt_timer.start()
	tele_warn.emitting = true

func _on_visible_on_screen_notifier_2d_screen_exited():
	if moving_enabled:
		printerr("Player out of bounds - reseting")
		moving_enabled = false
		velocity = Vector2.ZERO
		respawn_animator.play_backwards("PutBack")
		await respawn_animator.animation_finished
		reset_position_requested.emit()
		respawn_animator.play("PutBack")
		await respawn_animator.animation_finished
		moving_enabled = true
		velocity = Vector2.ZERO

func _on_tutorial_player_movement_enabled():
	await timer.timeout
	ray_cast.set_collision_mask_value(1,true)
	set_collision_mask_value(2,true)

func _on_tutorial_player_reset_screen_enabled():
	can_reset_screen = true

func _on_letterbox_collider_player_pull_requested(_direction):
	pullable = true

func _on_gamplay_pull_failed():
	pull_succsedded = false
	stop_harpoon()

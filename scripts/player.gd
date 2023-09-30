extends CharacterBody2D

const SPEED = 300.0

@onready var chain : Line2D = $Line2D
@onready var ray_cast : RayCast2D = $RayCast2D
@onready var walk_dust : GPUParticles2D = $WalkDust
@onready var animator :AnimationPlayer = $AnimationPlayer
@onready var harpoon_hit :GPUParticles2D = $HarpoonHit

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
	walk_dust.emitting = velocity.length() > 0
	
	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var angle_to_mouse = get_global_mouse_position().angle_to_point(global_position) - PI/2
		var target_rotation : float = snapped(angle_to_mouse,PI/2)
		if !is_equal_approx(rotation,target_rotation) and !rotate_tween and !harpoon_tween:
			start_rotation_tween(target_rotation)
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_fire_harpoon()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			stop_harpoon()

func start_rotation_tween(target_rotation : float):
	rotate_tween = create_tween()
	var old_rotation = rotation
	rotate_tween.tween_method(func(percent : float): rotation = lerp_angle(old_rotation,target_rotation,percent),0.0,1.0,0.1)
	rotate_tween.tween_callback(func():rotate_tween = null)
	rotate_tween.set_trans(Tween.TRANS_BOUNCE)

func try_fire_harpoon():
	if !harpoon_tween:
		var target = ray_cast.get_collision_point()
		harpoon_tween = create_tween()
		harpoon_tween.tween_method(func(percent : float): chain.points[0] = lerp(Vector2.ZERO,to_local(target), percent),0,1,.15)
		harpoon_tween.tween_callback(while_harpoon_out.bind(target))
		harpoon_tween.tween_callback(add_hit_fx)
		harpoon_direction = rotation
		animator.play("HarpoonOut")
		if ray_cast.get_collider() and ray_cast.get_collider().has_method("_on_player_pull_requested"):
			harpoon_target = ray_cast.get_collider()
			pull_requested.connect(harpoon_target._on_player_pull_requested)
	else:
		pull_requested.emit(harpoon_direction)
		animator.play("Pull")

func add_hit_fx():
	harpoon_hit.position = chain.points[0]
	harpoon_hit.emitting = true

func while_harpoon_out(target):
	harpoon_tween = create_tween()
	harpoon_tween.tween_callback(func(): rotation = target.angle_to_point(global_position) - PI/2)
	harpoon_tween.tween_callback(func(): chain.points[0] = to_local(target))
	harpoon_tween.tween_interval(.01)
	harpoon_tween.set_loops()

func stop_harpoon():
	if harpoon_tween:
		if harpoon_target and pull_requested.is_connected(harpoon_target._on_player_pull_requested):
			pull_requested.disconnect(harpoon_target._on_player_pull_requested)
		harpoon_tween.kill()
		harpoon_tween = create_tween()
		harpoon_tween.tween_method(func(vec : Vector2): chain.points[0] = vec,chain.points[1],Vector2.ZERO,.1)
		harpoon_tween.tween_callback(func(): harpoon_tween = null)
		animator.play("HarpoonIn")
		var angle_to_mouse = get_global_mouse_position().angle_to_point(global_position) - PI/2
		var target_rotation : float = snapped(angle_to_mouse,PI/2)
		harpoon_tween.tween_callback(start_rotation_tween.bind(target_rotation))


func _on_hit_box_area_entered(area : Area2D):
	velocity += (area.global_position - global_position).normalized() * SPEED

extends CharacterBody2D

const SPEED = 300.0

@onready var chain : Line2D = $Line2D
@onready var ray_cast : RayCast2D = $RayCast2D
@onready var walk_dust : GPUParticles2D = $WalkDust

var harpoon_tween : Tween
var rotate_tween :Tween

signal pull_requested(direction : Vector2)

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
		var target_rotation = abs(snapped(angle_to_mouse,PI/2))
		if !is_equal_approx(rotation,target_rotation) and !rotate_tween and !harpoon_tween:
			rotate_tween = create_tween()
			var old_rotation = rotation
			rotate_tween.tween_method(func(percent):rotation = lerp_angle(old_rotation,target_rotation,percent),0,1,0.1)
			rotate_tween.tween_callback(func():rotate_tween = null)
			#rotate_tween.set_trans(Tween.TRANS_BOUNCE)
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_fire_harpoon()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			stop_harpoon()

func try_fire_harpoon():
	if !harpoon_tween:
		harpoon_tween = create_tween()
		var target = ray_cast.get_collision_point()
		harpoon_tween.tween_method(func(percent : float): chain.points[0] = lerp(Vector2.ZERO,to_local(target), percent),0,1,.15)
		harpoon_tween.tween_callback(while_harpoon_out.bind(target))
	else:
		pull_requested.emit(Vector2(cos(rotation), sin(rotation)))
		

func while_harpoon_out(target):
	harpoon_tween = create_tween()
	harpoon_tween.tween_callback(func(): chain.points[0] = to_local(target))
	harpoon_tween.tween_interval(.01)
	harpoon_tween.set_loops()

func stop_harpoon():
	if harpoon_tween:
		harpoon_tween.kill()
		harpoon_tween = create_tween()
		harpoon_tween.tween_method(func(vec : Vector2): chain.points[0] = vec,chain.points[1],Vector2.ZERO,.1)
		harpoon_tween.tween_callback(func(): harpoon_tween = null)

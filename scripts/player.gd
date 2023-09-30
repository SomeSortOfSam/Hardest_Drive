extends CharacterBody2D

const SPEED = 300.0

@onready var chain : Line2D = $Line2D
@onready var ray_cast : RayCast2D = $RayCast2D

var harpoon_tween : Tween

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
	

	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var angle_to_mouse = up_direction.angle_to(get_global_mouse_position()) 
		var target_rotation = snapped(angle_to_mouse,PI/2)
		if !is_equal_approx(rotation,target_rotation) and !harpoon_tween:
			var tween = create_tween()
			tween.tween_property(self,"rotation",target_rotation,.1)
			tween.set_trans(Tween.TRANS_BOUNCE)
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_fire_harpoon()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			stop_harpoon()

func try_fire_harpoon():
	if !harpoon_tween:
		harpoon_tween = create_tween()
		var target = ray_cast.get_collision_point()
		harpoon_tween.tween_method(func(percent : float): chain.points[1] = lerp(Vector2.ZERO,to_local(target), percent),0,1,.15)
		harpoon_tween.set_ease(Tween.EASE_IN)
		harpoon_tween.tween_callback(while_harpoon_out.bind(target))

func while_harpoon_out(target):
	harpoon_tween = create_tween()
	harpoon_tween.tween_callback(func(): chain.points[1] = to_local(target))
	harpoon_tween.tween_interval(.01)
	harpoon_tween.set_loops()

func stop_harpoon():
	if harpoon_tween:
		harpoon_tween.kill()
		harpoon_tween = create_tween()
		harpoon_tween.tween_method(func(vec : Vector2): chain.points[1] = vec,chain.points[1],Vector2.ZERO,.1)
		harpoon_tween.tween_callback(func(): harpoon_tween = null)

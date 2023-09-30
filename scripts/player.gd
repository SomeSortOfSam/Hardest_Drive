extends CharacterBody2D

const SPEED = 300.0

var target_rotation : float
var is_harpooning := false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _process(delta):
	if !is_harpooning and !is_equal_approx(target_rotation,rotation):
		rotation = lerp(rotation,target_rotation,.6)

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
		target_rotation = snapped(angle_to_mouse,PI/2)
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_fire_harpoon()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			stop_harpoon()

func try_fire_harpoon():
	is_harpooning = true

func stop_harpoon():
	is_harpooning = false

extends CharacterBody2D

var movement_speed: float = 200.0
var movement_target_position: Vector2 = Vector2(60.0,180.0)
var nav_enabled := true

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var player = $"../TileMap/Player"
@onready var sprite :Sprite2D = $Sprite2D
@onready var timer : Timer = $Timer

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0

	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(player.global_position)

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if nav_enabled:
		if navigation_agent.is_navigation_finished():
			set_movement_target(player.global_position)
			return

		var current_agent_position: Vector2 = global_position
		var next_path_position: Vector2 = navigation_agent.get_next_path_position()

		var new_velocity: Vector2 = next_path_position - current_agent_position
		new_velocity = new_velocity.normalized()
		new_velocity = new_velocity * movement_speed
		velocity = new_velocity

	move_and_slide()
	face_target()

func face_target():
	if navigation_agent.target_position.x > global_position.x:
		sprite.scale = Vector2(-1,1)
	else:
		sprite.scale = Vector2(1,1)

func _on_navigation_agent_2d_waypoint_reached(details):
	set_movement_target(player.global_position)

func _on_hurt_box_area_entered(area):
	velocity += (global_position - area.global_position).normalized() * movement_speed * 3
	var cell = tilemap.local_to_map(position)
	tilemap.erase_cell(0,cell)
	tilemap.force_update()
	nav_enabled = false
	timer.start()
	await timer.timeout
	nav_enabled = true

extends CharacterBody2D

var movement_speed: float = 200.0
var movement_target_position: Vector2 = Vector2(60.0,180.0)

@export var nav_enabled := false
@export var death_sounds : Array[AudioStream]

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var player = $"../TileMap/Player"
@onready var sprite :Sprite2D = $Sprite2D
@onready var timer : Timer = $Timer
@onready var tilemap :TileMap = $"../TileMap"
@onready var animator :AnimationPlayer = $"AnimationPlayer"
@onready var hurtbox_shape :CollisionShape2D = $"HurtBox/CollisionShape2D"
@onready var death_sound : AudioStreamPlayer2D = $DeathSound

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
	set_movement_target(get_target())

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		on_navigation_finished()

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = navigation_agent.get_next_path_position()

	var new_velocity: Vector2 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized()
	new_velocity = new_velocity * movement_speed
	velocity = new_velocity

	if move_and_slide():
		set_movement_target(player.global_position)
	face_target()

func get_target() -> Vector2:
	return player.global_position

# called every physics frame
func on_navigation_finished():
	set_movement_target(get_target())

func face_target():
	if navigation_agent.target_position.x > global_position.x:
		sprite.scale = Vector2(-1,1)
	else:
		sprite.scale = Vector2(1,1)

func die():
	call_deferred("disable_hitbox")
	nav_enabled = false
	animator.play("Destroy")
	death_sound.stream = death_sounds.pick_random()
	death_sound.play()
	await animator.animation_finished
	if death_sound.playing:
		await death_sound.finished
	queue_free()

func disable_hitbox():
	hurtbox_shape.disabled = true

func _on_hurt_box_area_entered(area : Area2D):
	if area.get_parent().get_script() != get_script():
		velocity += (global_position - area.global_position).normalized() * movement_speed * 3
		var cell = tilemap.local_to_map(tilemap.to_local(global_position))
		tilemap.erase_cell(0,cell)
		tilemap.set_cells_terrain_connect(0,[cell],0,-1)
		nav_enabled = false
		timer.start()
		await timer.timeout
		nav_enabled = true

func _on_hit_box_area_entered(area):
	if area.get_parent().get_script() != get_script():
		die()

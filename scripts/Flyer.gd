extends "res://scripts/enemy.gd"

func _physics_process(delta):
	var new_velocity: Vector2 = to_local(get_target()) 
	new_velocity = new_velocity.normalized()
	new_velocity = new_velocity * movement_speed
	velocity = new_velocity
	move_and_slide()
	face_target()

extends Area2D

@export var enemy_scene : PackedScene

@onready var timer : Timer = $Timer



func _on_area_exited(_area):
	if visible:
		timer.start()
		if !timer.timeout.is_connected(spawn_enemy):
			timer.timeout.connect(spawn_enemy,CONNECT_ONE_SHOT)

func spawn_enemy():
	if !has_overlapping_areas():
		var enemy = enemy_scene.instantiate()
		enemy.position = position
		get_parent().add_child(enemy)

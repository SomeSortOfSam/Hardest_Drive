extends Area2D
@export var enemy_scene : PackedScene
func _on_area_exited(area):
	call_deferred("spawn_enemy")

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.position = position
	get_parent().add_child(enemy)

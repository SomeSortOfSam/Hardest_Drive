extends Area2D

@export var enemy_scene : PackedScene

func _on_area_exited(area):
	get_parent().call_deferred("add_child",enemy_scene.instantiate())

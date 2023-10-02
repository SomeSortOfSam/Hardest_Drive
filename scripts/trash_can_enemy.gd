extends "res://scripts/enemy.gd"

var ai_tween : Tween

func on_navigation_finished():
	if !ai_tween:
		ai_tween = create_tween()
		ai_tween.tween_callback(_on_hurt_box_area_entered.bind(tilemap))
		ai_tween.tween_interval(5)
		ai_tween.tween_callback(func(): set_movement_target(get_target()))
		ai_tween.tween_callback(func(): ai_tween = null)

func get_target():
	return tilemap.to_global(tilemap.map_to_local(tilemap.get_used_cells(0).pick_random()))

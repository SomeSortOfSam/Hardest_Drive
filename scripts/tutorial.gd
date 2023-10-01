extends CanvasLayer

@onready var animator : AnimatedSprite2D = $Control/AnimatedSprite2D

var triggered_count := 0

signal player_movement_enabled
signal player_reset_screen_enabled
signal done

func _unhandled_input(event):
	if ((triggered_count < 2 or (triggered_count > 2 and triggered_count <= 4))
	 and event is InputEventMouseButton and\
	 event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or\
	(triggered_count == 2 and
	(event.is_action_pressed("player_up") or event.is_action_pressed("player_down") or \
	event.is_action_pressed("player_left") or event.is_action_pressed("player_right"))) or \
	(triggered_count == 5 and (event is InputEventMouseButton and\
	 event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed())) or\
	(triggered_count == 6 and event.is_action_pressed("reset_screen") ):
		triggered_count += 1
		if triggered_count == 1:
			animator.play("pull")
			player_movement_enabled.emit()
		if triggered_count == 2:
			animator.play("walk")
		if triggered_count == 3:
			animator.play("harpoon")
		if triggered_count == 4:
			animator.play("pull")
		if triggered_count == 5:
			animator.play("unhook")
		if triggered_count == 6:
			animator.play("space")
			player_reset_screen_enabled.emit()
		if triggered_count >= 7:
			animator.hide()
			done.emit()

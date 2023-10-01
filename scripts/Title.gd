extends TextureRect

@onready var animator = $"../AnimationPlayer"

var triggered_count := 0
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		triggered_count += 1
	if triggered_count == 2:
		animator.play("HideTitle")
		triggered_count += 1

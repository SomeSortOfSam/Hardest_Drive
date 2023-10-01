extends TextureRect

@onready var animator = $"../AnimationPlayer"

var triggered := false
func _unhandled_input(event):
	if !triggered and event is InputEventMouseButton:
		animator.play("HideTitle")
		triggered = true

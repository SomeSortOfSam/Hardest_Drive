extends TextureRect

@onready var animator = $"../AnimationPlayer"

var triggered := false
func _unhandled_input(event):
	if !triggered and not event is InputEventMouseMotion:
		animator.play("HideTitle")
		triggered = true

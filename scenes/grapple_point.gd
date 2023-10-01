extends StaticBody2D

@onready var animator :AnimationPlayer = $AnimationPlayer

func _on_player_pull_requested(_direction):
	animator.play("HitShine")

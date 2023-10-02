extends StaticBody2D

@onready var animator :AnimationPlayer = $AnimationPlayer
@onready var audio : AudioStreamPlayer2D = $AudioStreamPlayer2D

func _on_player_pull_requested(_direction,_player):
	animator.play("HitShine")
	audio.play()

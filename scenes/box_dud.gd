extends "res://scenes/grapple_point.gd"

func _on_player_pull_requested(_direction,player):
	pass

func _on_player_harpoon_hit(player):
	animator.play("HitShine")
	await animator.animation_finished
	player.stop_harpoon()


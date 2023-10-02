extends "res://scenes/grapple_point.gd"

func _on_player_pull_requested(_direction,_player):
	pass

func _on_player_harpoon_hit(player):
	animator.play("HitShine")
	player.pull_succsedded = false
	await animator.animation_finished
	player.stop_harpoon()


extends Area2D

signal player_pull_requested(direction : float)

func _on_player_pull_requested(direction : float):
	player_pull_requested.emit(direction)

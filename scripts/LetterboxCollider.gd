extends Area2D

signal player_pull_requested(direction : float)

func _on_player_pull_requested(direction : float, _player):
	player_pull_requested.emit(direction)

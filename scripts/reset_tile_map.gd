extends TileMap

@onready var player = $Player

func _on_player_reset_position_requested():
	player.position = map_to_local(get_used_cells(0).pick_random())

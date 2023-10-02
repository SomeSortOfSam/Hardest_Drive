extends TileMap

@onready var player = $Player
@onready var letter_box = $"../Camera2D"

signal lost

func _on_player_reset_position_requested():
	var valid_cells : Array[Vector2i] = []
	for cell in get_used_cells(0):
		if get_cell_tile_data(0,cell).terrain != -1 and letter_box.last_inner_rect.has_point(to_global(map_to_local(cell))):
			valid_cells.append(cell)
	if valid_cells.size() <= 0:
		lost.emit()
		return
	player.position = map_to_local(valid_cells.pick_random())

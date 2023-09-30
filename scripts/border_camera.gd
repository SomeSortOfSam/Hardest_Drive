extends CanvasItem

const minimum_border_distance = 5.0

@onready var collision_polygon : CollisionPolygon2D = $Camera2D/LetterboxCollider/CollisionPolygon2D
@onready var render_polygon : Polygon2D = $Camera2D/LetterboxCollider/Polygon2D
@onready var border_line : Line2D = $Camera2D/LetterboxCollider/Line2D
@onready var ray_cast : RayCast2D = $RayCast2D
@onready var tile_map : TileMap = $TileMap

var minimum_inner_rect : Rect2
var inner_rect : Rect2

func _ready():
	call_deferred("call_deferred","recalculate_offsets")
	call_deferred("call_deferred","recalculate_border")
	get_viewport().size_changed.connect(recalculate_offsets)
	get_viewport().size_changed.connect(recalculate_border)

func recalculate_border():
	var polygon_rect := get_viewport_rect()
	polygon_rect.size *= get_viewport_transform().get_scale()
	
	
	assert(polygon_rect.encloses(inner_rect))
	
	var polygon := get_points_from_rect(polygon_rect)
	var inner_line := get_points_from_rect_counter_clock(inner_rect)
	
	polygon.append_array(inner_line)
	polygon.append(Vector2.ZERO)
	
	render_polygon.polygon = polygon
	collision_polygon.polygon = polygon
	border_line.points = inner_line

func get_points_from_rect(rect : Rect2) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	polygon.append(rect.position)
	polygon.append(rect.position + Vector2(rect.size.x,0))
	polygon.append(rect.position + rect.size)
	polygon.append(rect.position + Vector2(0,rect.size.y))
	polygon.append(rect.position)
	return polygon

func get_points_from_rect_counter_clock(rect : Rect2) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	polygon.append(rect.position)
	polygon.append(rect.position + Vector2(0,rect.size.y))
	polygon.append(rect.position + rect.size)
	polygon.append(rect.position + Vector2(rect.size.x,0))
	polygon.append(rect.position)
	return polygon

func recalculate_offsets():
	var rect = get_viewport_rect()
	rect.size *= get_viewport_transform().get_scale()
	inner_rect = rect
	inner_rect = inner_rect.grow(-minimum_border_distance)
	minimum_inner_rect = inner_rect
	assert(rect.encloses(inner_rect))
	assert(rect.size.x - inner_rect.size.x == minimum_border_distance * 2)
	assert(rect.size.y - inner_rect.size.y == minimum_border_distance * 2)

func _on_letterbox_collider_player_pull_requested(direction : float):
	var rect := get_viewport_rect()
	rect.size *= get_viewport_transform().get_scale()
	
	if direction < 0:
		direction = TAU + direction
	direction = fmod(direction + 3*(PI/2),TAU)
	direction = deg_to_rad(round(rad_to_deg(direction)))
	var side_index : int = direction/(PI/2)
	
	inner_rect = inner_rect.grow_side(side_index,-tile_map.tile_set.tile_size.x)
	inner_rect = inner_rect.grow_side((side_index + 2) % 4,-tile_map.tile_set.tile_size.x)
	
	inner_rect = inner_rect.grow_side((side_index + 1) % 4,tile_map.tile_set.tile_size.x)
	inner_rect = inner_rect.grow_side((side_index + 3) % 4,tile_map.tile_set.tile_size.x)
	
	inner_rect = minimum_inner_rect.intersection(inner_rect)
	
	assert(rect.encloses(inner_rect))
	recalculate_border()


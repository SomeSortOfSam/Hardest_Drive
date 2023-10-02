extends CanvasItem

const minimum_border_distance = 5.0

@onready var area_collision_polygon : CollisionPolygon2D = $LetterboxCollider/CollisionPolygon2D
@onready var body_collision_polygon : CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D
@onready var render_polygon : Polygon2D = $LetterboxCollider/Polygon2D
@onready var border_line : Line2D = $LetterboxCollider/Line2D
@onready var tile_map : TileMap = $"../TileMap"

var minimum_inner_rect : Rect2
var last_inner_rect : Rect2
var can_reset_screen := false

signal pull_failed

func _ready():
	start_tutorial()

func _unhandled_input(event):
	if can_reset_screen and event.is_action_pressed("reset_screen"):
		recalculate_border(recalculate_offsets())

func start_tutorial():
	recalculate_border(recalculate_offsets().grow_side(SIDE_BOTTOM,-64).grow_side(SIDE_TOP,-64 * 3))

func recalculate_border(inner_rect : Rect2):
	var polygon_rect := get_viewport_rect()
	polygon_rect.size *= get_viewport_transform().get_scale()
	
	assert(polygon_rect.encloses(inner_rect))
	var polygon = get_points_from_rect(polygon_rect)
	var line_rect = minimum_inner_rect.intersection(inner_rect)
	var line = get_points_from_rect_counter_clock(line_rect)
	polygon.append_array(line)
	area_collision_polygon.polygon = polygon
	
	var prev_inner_rect = last_inner_rect
	last_inner_rect = inner_rect
	
	create_tween().tween_method(recalculate_border_step.bind(polygon_rect,inner_rect,prev_inner_rect),0.0,1.0,0.5)\
	.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT) #oh dios mio

func recalculate_border_step(percent : float, polygon_rect : Rect2, inner_rect : Rect2, prev_inner_rect : Rect2):
	var polygon = get_points_from_rect(polygon_rect)
	var line_rect = lerp_rect_2(prev_inner_rect,inner_rect,percent)
	line_rect = minimum_inner_rect.intersection(line_rect)
	var line = get_points_from_rect_counter_clock(line_rect)
	polygon.append_array(line)
	set_polygon(polygon,line)

func lerp_rect_2(start : Rect2, end : Rect2, percent : float) -> Rect2:
	var output := Rect2(lerp(start.position,end.position,percent),lerp(start.size,end.size,percent))
	output.size.x = max(output.size.x,0)
	output.size.y = max(output.size.y,0)
	return output

func set_polygon(polygon : PackedVector2Array, inner_line : PackedVector2Array):
	render_polygon.polygon = polygon
	body_collision_polygon.polygon = polygon
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

func recalculate_offsets() -> Rect2:
	var outer_rect = get_viewport_rect()
	outer_rect.size *= get_viewport_transform().get_scale()
	var inner_rect = outer_rect
	inner_rect = inner_rect.grow(-minimum_border_distance)
	minimum_inner_rect = inner_rect
	assert(outer_rect.encloses(inner_rect))
	assert(outer_rect.size.x - inner_rect.size.x == minimum_border_distance * 2)
	assert(outer_rect.size.y - inner_rect.size.y == minimum_border_distance * 2)
	return inner_rect

func _on_letterbox_collider_player_pull_requested(direction : float):
	var rect := get_viewport_rect()
	rect.size *= get_viewport_transform().get_scale()
	
	if direction < 0:
		direction = TAU + direction
	direction = fmod(direction + 3*(PI/2),TAU)
	direction = deg_to_rad(round(rad_to_deg(direction)))
	@warning_ignore("narrowing_conversion")
	var side_index : int = int(direction/(PI/2)) % 4
	
	var proposed_inner_rect = last_inner_rect
	
	proposed_inner_rect = proposed_inner_rect.grow_side(side_index,-tile_map.tile_set.tile_size.x)
	proposed_inner_rect = proposed_inner_rect.grow_side((side_index + 2) % 4,-tile_map.tile_set.tile_size.x)
	
	proposed_inner_rect = proposed_inner_rect.grow_side((side_index + 1) % 4,tile_map.tile_set.tile_size.x)
	proposed_inner_rect = proposed_inner_rect.grow_side((side_index + 3) % 4,tile_map.tile_set.tile_size.x)
	
	if proposed_inner_rect.size.x <= 0 or proposed_inner_rect.size.y <= 0:
		print(pull_failed.get_connections())
		pull_failed.emit()
		return
	
	proposed_inner_rect = minimum_inner_rect.intersection(proposed_inner_rect)
	assert(rect.encloses(proposed_inner_rect))
	
	recalculate_border(proposed_inner_rect)

func _on_tutorial_player_reset_screen_enabled():
	can_reset_screen = true


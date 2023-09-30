extends CanvasItem

@onready var collision_polygon : CollisionPolygon2D = $Camera2D/LetterboxCollider/CollisionPolygon2D
@onready var render_polygon : Polygon2D = $Camera2D/LetterboxCollider/Polygon2D
@onready var border_line : Line2D = $Camera2D/LetterboxCollider/Line2D
@onready var ray_cast : RayCast2D = $RayCast2D
@onready var tile_map : TileMap = $TileMap

var left_offset : Vector2
var right_offset : Vector2

func _ready():
	call_deferred("call_deferred","recalculate_offsets")
	call_deferred("call_deferred","recalculate_border")
	get_viewport().size_changed.connect(recalculate_offsets)
	get_viewport().size_changed.connect(recalculate_border)

func recalculate_border():
	var polygon : PackedVector2Array = []
	var polygon_rect := get_viewport_rect()
	polygon_rect.size *= get_viewport_transform().get_scale()
	polygon.append(Vector2.ZERO)
	polygon.append(Vector2(polygon_rect.size.x,0))
	polygon.append(polygon_rect.size)
	polygon.append(Vector2(0,polygon_rect.size.y))
	polygon.append(Vector2.ZERO)
	
	
	var inner_line : PackedVector2Array = []
	var inner_rect : Rect2 = Rect2(left_offset,right_offset -left_offset)
	inner_line.append(left_offset)
	inner_line.append(left_offset + Vector2(0,right_offset.y))
	inner_line.append(left_offset + right_offset)
	inner_line.append(left_offset + Vector2(right_offset.x,0))
	inner_line.append(left_offset)
	
	if !polygon_rect.encloses(inner_rect):
		print(polygon_rect,inner_rect)
		return
	
	polygon.append_array(inner_line)
	polygon.append(Vector2.ZERO)
	
	render_polygon.polygon = polygon
	collision_polygon.polygon = polygon
	border_line.points = inner_line

func recalculate_offsets():
	var rect = get_viewport_rect()
	ray_cast.position = Vector2(rect.size.x,0)/2
	ray_cast.target_position = Vector2.DOWN * 1000
	ray_cast.force_raycast_update()
	await get_tree().physics_frame
	left_offset.y = ray_cast.get_collision_point().y
	ray_cast.position = Vector2(0,rect.size.y)/2
	ray_cast.target_position = Vector2.RIGHT * 1000
	await get_tree().physics_frame
	left_offset.x = ray_cast.get_collision_point().x
	
	ray_cast.position = Vector2(rect.size.x/2,rect.size.y)
	ray_cast.target_position = Vector2.UP * 1000
	ray_cast.force_raycast_update()
	await get_tree().physics_frame
	right_offset.y = ray_cast.get_collision_point().y
	ray_cast.position = Vector2(rect.size.x,rect.size.y/2)
	ray_cast.target_position = Vector2.LEFT * 1000
	ray_cast.force_raycast_update()
	await get_tree().physics_frame
	right_offset.x = ray_cast.get_collision_point().x

func _on_player_pull_requested(direction : Vector2):
	var rect := get_viewport_rect()
	rect.size *= get_viewport_transform().get_scale()
	if direction.x != 0:
		left_offset.x -= tile_map.tile_set.tile_size.x
		right_offset.x += tile_map.tile_set.tile_size.x
		left_offset.y += tile_map.tile_set.tile_size.y
		right_offset.y += tile_map.tile_set.tile_size.y
	else:
		left_offset.x += tile_map.tile_set.tile_size.x
		right_offset.x -= tile_map.tile_set.tile_size.x
		left_offset.y -= tile_map.tile_set.tile_size.y
		right_offset.y -= tile_map.tile_set.tile_size.y
	left_offset.x = max(rect.position.x,left_offset.x)
	left_offset.y = max(rect.position.y,left_offset.y)
	right_offset.x = min(rect.position.x + rect.size.x,right_offset.x)
	right_offset.y = min(rect.position.y + rect.size.y,right_offset.y)
	left_offset.x = min(left_offset.x,right_offset.x)
	left_offset.y = min(left_offset.y,right_offset.y)
	recalculate_border()
		

extends CanvasItem

@onready var collision_polygon : CollisionPolygon2D = $Camera2D/LetterboxCollider/CollisionPolygon2D
@onready var render_polygon : Polygon2D = $Camera2D/LetterboxCollider/Polygon2D
@onready var border_line : Line2D = $Camera2D/LetterboxCollider/Line2D
@onready var ray_cast : RayCast2D = $RayCast2D

func _ready():
	call_deferred("recalculate_border")
	get_viewport().size_changed.connect(recalculate_border)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func recalculate_border():
	var polygon : PackedVector2Array = []
	var rect = get_viewport_rect()
	rect.size *= get_viewport_transform().get_scale()
	polygon.append(Vector2.ZERO)
	polygon.append(Vector2(rect.size.x,0))
	polygon.append(rect.size)
	polygon.append(Vector2(0,rect.size.y))
	polygon.append(Vector2.ZERO)
	
	var left_offset : Vector2
	ray_cast.position = Vector2(rect.size.x,0)/2
	ray_cast.target_position = Vector2.DOWN * 1000
	ray_cast.force_raycast_update()
	await get_tree().physics_frame
	left_offset.y = ray_cast.get_collision_point().y
	ray_cast.position = Vector2(0,rect.size.y)/2
	ray_cast.target_position = Vector2.RIGHT * 1000
	await get_tree().physics_frame
	left_offset.x = ray_cast.get_collision_point().x
	
	var right_offset : Vector2
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
	
	var inner_line : PackedVector2Array = []
	inner_line.append(left_offset)
	inner_line.append(left_offset + Vector2(0,right_offset.y))
	inner_line.append(left_offset + right_offset)
	inner_line.append(left_offset + Vector2(right_offset.x,0))
	inner_line.append(left_offset)
	
	polygon.append_array(inner_line)
	polygon.append(Vector2.ZERO)
	
	render_polygon.polygon = polygon
	collision_polygon.polygon = polygon
	border_line.points = inner_line

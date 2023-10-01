extends CanvasLayer

@onready var animator : AnimatedSprite2D = $Control/AnimatedSprite2D
@onready var sprite_mover : AnimationPlayer = $AnimationPlayer
@onready var banner_holder: Control = $BannerHolder
@onready var messages :Control = $BannerHolder/Messages
@onready var banner_mover : AnimationPlayer = $BannerHolder/AnimationPlayer

var triggered_count := 0

signal player_movement_enabled
signal player_reset_screen_enabled
signal done

func _unhandled_input(event):
	if ((triggered_count < 2 or (triggered_count > 2 and triggered_count <= 4))
	 and event is InputEventMouseButton and\
	 event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or\
	(triggered_count == 2 and
	(event.is_action_pressed("player_up") or event.is_action_pressed("player_down") or \
	event.is_action_pressed("player_left") or event.is_action_pressed("player_right"))) or \
	(triggered_count == 5 and (event is InputEventMouseButton and\
	 event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed())) or\
	(triggered_count == 6 and event.is_action_pressed("reset_screen") ):
		triggered_count += 1
		if triggered_count == 1:
			swap_banner_to(2)
			animator.play("pull")
			player_movement_enabled.emit()
		if triggered_count == 2:
			swap_banner_to(-1)
			swap_sprite_to("walk")
		if triggered_count == 3:
			swap_banner_to(1)
			swap_sprite_to("harpoon")
		if triggered_count == 4:
			swap_banner_to(2)
			animator.play("pull")
		if triggered_count == 5:
			swap_banner_to(3)
			swap_sprite_to("unhook")
		if triggered_count == 6:
			swap_banner_to(4)
			swap_sprite_to("space")
			player_reset_screen_enabled.emit()
		if triggered_count >= 7:
			banner_mover.play("BannerOut")
			sprite_mover.play("SpriteOut")
			done.emit()

func swap_sprite_to(name :String):
	sprite_mover.play("SpriteChange")
	await sprite_mover.animation_finished
	animator.play(name)
	sprite_mover.play_backwards("SpriteChange")

func swap_banner_to(index :int):
	banner_mover.play("ChangeBanner")
	await banner_mover.animation_finished
	if index == -1:
		banner_holder.visible = false
	else:
		banner_holder.visible = true
		for child in messages.get_children():
			child.visible = child.get_index() == index
	banner_mover.play_backwards("ChangeBanner")

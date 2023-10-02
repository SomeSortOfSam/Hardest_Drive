extends Node2D

@export var levels : Array[PackedScene]

@onready var audio : AudioStreamPlayer = $NewWave

var tutorial_done := false
var level_index = -1
var current_level : Node2D
var enemey_count = 0

func play_next_level():
	if current_level:
		current_level.queue_free()
	level_index += 1
	current_level = levels[level_index].instantiate()
	add_child(current_level)
	for child in current_level.get_children():
		if child.is_class("EnemeySpawner"):
			child.enemy_spawned.connect(on_enemey_spawned)
	audio.play()

func on_enemey_spawned(enemy : Node2D):
	enemey_count += 1
	enemy.tree_exited.connect(func(): enemey_count -= 1)

func _on_tutorial_done():
	play_next_level()
	(func(): tutorial_done = true).call_deferred()

func _on_player_screen_reset():
	if tutorial_done and enemey_count == 0:
		play_next_level()

extends Node2D

@export var levels : Array[PackedScene]
@export var drone_track : AudioStream
@export var droneless_track : AudioStream

@onready var new_wave_audio : AudioStreamPlayer = $NewWave
@onready var music : AudioStreamPlayer = $Music

var tutorial_done := false
var level_index = -1
var current_level : Node2D
var enemey_count = 0

func play_next_level():
	if current_level:
		current_level.queue_free()
	level_index += 1
	current_level = levels[level_index].instantiate()
	for child in current_level.get_children():
		if child.has_method("spawn_enemy"):
			child.enemy_spawned.connect(on_enemey_spawned)
	add_child(current_level)
	new_wave_audio.play()
	switch_track(drone_track)

func switch_track(new_track : AudioStream):
	var playback_position = music.get_playback_position()
	music.stream = new_track
	music.play(playback_position)

func on_enemey_spawned(enemy : Node2D):
	enemey_count += 1
	enemy.tree_exited.connect(on_enemy_die)

func on_enemy_die():
	enemey_count -= 1
	if enemey_count <= 0:
		switch_track(droneless_track)

func _on_tutorial_done():
	play_next_level()
	(func(): tutorial_done = true).call_deferred()

func _on_player_screen_reset():
	if tutorial_done and enemey_count <= 0:
		play_next_level()

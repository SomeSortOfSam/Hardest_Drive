class_name EnemySpawner
extends Node2D

@export var enemy_scene : PackedScene

@onready var timer : Timer = $Timer

signal enemy_spawned(enemy)

func _ready():
	spawn_enemy()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.position = position
	get_parent().call_deferred("add_child",enemy)
	enemy_spawned.emit(enemy)

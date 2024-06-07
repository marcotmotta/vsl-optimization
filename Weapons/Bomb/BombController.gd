extends Node2D

var bomb_scene = preload("res://Weapons/Bomb/Bomb.tscn")
var map

func _ready():
	map = get_parent().get_parent()

func _get_random_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var selected_enemy = null
	var selected_enemy_direction = Vector2.ZERO

	if enemies:
		selected_enemy = enemies.pick_random()
		selected_enemy_direction = (selected_enemy.global_position - global_position).normalized()

	return {
		'enemy': selected_enemy,
		'direction': selected_enemy_direction
	}

func _on_spawn_timer_timeout():
	for i in range(3):
		var selected_enemy = _get_random_enemy()
		if selected_enemy.enemy:
			var bomb_instance = bomb_scene.instantiate()
			bomb_instance.p2 = ((selected_enemy.enemy.global_position - global_position) / 1.7) + global_position
			bomb_instance.global_position = global_position
			bomb_instance.direction = selected_enemy.direction
			#bomb_instance.bounce_count = 2
			#bomb_instance.has_explosion = true
			#bomb_instance.bonus_aoe = 1
			map.add_child(bomb_instance)

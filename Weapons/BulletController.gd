extends Node2D

var bullet_scene = preload("res://Weapons/Bullet.tscn")

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

func _get_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var selected_enemy = null
	var selected_enemy_direction = Vector2.ZERO
	var selected_enemy_distance = Vector2.ZERO
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if (not selected_enemy) or (selected_enemy and (enemy.global_position - global_position).length() < selected_enemy_distance):
			selected_enemy = enemy
			selected_enemy_distance = (enemy.global_position - global_position).length()
			selected_enemy_direction = (enemy.global_position - global_position).normalized()

	return {
		'enemy': selected_enemy,
		'direction': selected_enemy_direction
	}

func _on_timer_timeout():
	for i in range(5):
		var selected_enemy = _get_random_enemy()
		if selected_enemy.enemy:
			var bullet = bullet_scene.instantiate()
			bullet.global_position = global_position
			bullet.direction = selected_enemy.direction
			get_parent().get_parent().add_child(bullet)

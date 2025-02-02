extends Node2D

var fireball_scene = preload("Fireball.tscn")
var map

func _ready():
	map = get_parent().get_parent()

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

func _on_spawn_timer_timeout():
	var selected_enemy = _get_closest_enemy()
	if selected_enemy.enemy:
		for i in range(1):
			var shift = 0 if i == 0 else randi_range(-25, 25)
			var fireball_instance = fireball_scene.instantiate()
			fireball_instance.fireball_scene = fireball_scene
			fireball_instance.global_position = global_position
			fireball_instance.direction = selected_enemy.direction.rotated(deg_to_rad(shift))
			fireball_instance.bounce_count = 0
			fireball_instance.has_explosion = false
			fireball_instance.bonus_aoe = 0
			map.add_child(fireball_instance)

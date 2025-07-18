extends Node2D

var rang_scene = preload("Rang.tscn")
var map

var base_speed = 400
var base_duration = 0.8

var upgrades

func _ready():
	map = get_parent().get_parent()
	upgrades = get_parent().current_abilities["Rang"].upgrades

func _get_closest_enemy():
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
		for i in range(upgrades.get("count", 0) + 1):
			var shift = 0 if i == 0 else randi_range(-25, 25)
			var rang_instance = rang_scene.instantiate()
			rang_instance.rang_scene = rang_scene
			rang_instance.global_position = global_position
			rang_instance.direction = selected_enemy.direction.rotated(deg_to_rad(shift))
			rang_instance.damage = 10 * (upgrades.get("damage", 0) + 1)
			rang_instance.speed = base_speed + (upgrades.get("range", 0) * 200)
			rang_instance.duration = base_duration
			rang_instance.bonus_aoe = 0
			map.add_child(rang_instance)

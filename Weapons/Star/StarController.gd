extends Node2D

var star_scene = preload("Star.tscn")
var map

var upgrades

func _ready():
	map = get_parent().get_parent()
	upgrades = get_parent().current_abilities["Star"].upgrades

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
		var count = upgrades.get("count", 0) + 1
		var offset = 360 / count
		for i in range(count):
			var shift = offset * i
			var star_instance = star_scene.instantiate()
			star_instance.star_scene = star_scene
			star_instance.global_position = global_position
			star_instance.direction = selected_enemy.direction.rotated(deg_to_rad(shift))
			star_instance.damage = 10 * (upgrades.get("damage", 0) + 1)
			star_instance.bonus_aoe = 0
			map.add_child(star_instance)

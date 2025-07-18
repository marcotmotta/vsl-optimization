extends Node2D

var lightning_scene = preload("Lightning.tscn")
var map

var upgrades

func _ready():
	map = get_parent().get_parent()
	upgrades = get_parent().current_abilities["Lightning"].upgrades

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
	for i in range(upgrades.get("count", 0) + 1):
		var selected_enemy = _get_random_enemy()
		if selected_enemy.enemy:
			var lightning_instance = lightning_scene.instantiate()
			#lightning_instance.lightning_scene = lightning_scene
			lightning_instance.global_position = global_position
			lightning_instance.direction = selected_enemy.direction
			lightning_instance.damage = 10 * (upgrades.get("damage", 0) + 1)
			#lightning_instance.bounce_count = 2
			#lightning_instance.has_explosion = true
			#lightning_instance.bonus_aoe = 1
			map.add_child(lightning_instance)

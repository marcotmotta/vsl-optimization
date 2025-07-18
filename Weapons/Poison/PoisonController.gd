extends Node2D

var poison_scene = preload("res://Weapons/Poison/Poison.tscn")
var map

var base_aoe_range = 50
var base_duration = 1.5

var upgrades

func _ready():
	map = get_parent().get_parent()
	upgrades = get_parent().current_abilities["Poison"].upgrades

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
			var poison_instance = poison_scene.instantiate()
			poison_instance.target_position = ((selected_enemy.enemy.global_position - global_position) / 1.7) + global_position
			poison_instance.global_position = global_position
			poison_instance.direction = selected_enemy.direction
			poison_instance.damage = 20 * (upgrades.get("damage", 0) + 1)
			poison_instance.aoe_range = base_aoe_range + (upgrades.get("area", 0) * 10)
			poison_instance.duration = base_duration + (upgrades.get("duration", 0) * 1)
			#poison_instance.bounce_count = 2
			#poison_instance.has_explosion = true
			#poison_instance.bonus_aoe = 1
			map.add_child(poison_instance)

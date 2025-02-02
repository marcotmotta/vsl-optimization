extends Node2D

var radius = 50

func _ready():
	checkCollisions()

func checkCollisions():
	var spatial_group = get_parent().getSpatialGroup(global_position.x, global_position.y)

	var nearby_spatial_groups = get_parent().getExpandedSpatialGroups(spatial_group, ceil(radius / get_parent().CELL_WIDTH) + 1)
	var nearby_enemies = []
	for group in nearby_spatial_groups:
		nearby_enemies.append_array(get_parent().enemies_spatial_groups[group])

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.global_position - global_position).length()
			if distance < radius + enemy.size:
				enemy.die()

func _on_hit_timer_timeout():
	checkCollisions()

func _on_expiration_timer_timeout():
	queue_free()

extends Node2D

func _process(delta):
	var spatial_group = get_parent().get_parent().getSpatialGroup(global_position.x, global_position.y)

	var nearby_spatial_groups = get_parent().get_parent().getExpandedSpatialGroups(spatial_group, ceil(100 / 50))
	var nearby_enemies = []
	for group in nearby_spatial_groups:
		nearby_enemies.append_array(get_parent().get_parent().enemies_spatial_groups[group])

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.global_position - global_position).length()
			if distance < 100:
				enemy.die()

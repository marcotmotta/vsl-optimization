extends Node2D

var base_aoe_range = 80

var upgrades

func _ready() -> void:
	upgrades = get_parent().current_abilities["Area"].upgrades

func checkCollisions():
	var aoe_range = base_aoe_range + (upgrades.get("area", 0) * 10)

	$GPUParticles2D.process_material.emission_ring_radius = aoe_range
	$GPUParticles2D.process_material.emission_ring_inner_radius = aoe_range

	var spatial_group = get_parent().get_parent().getSpatialGroup(global_position.x, global_position.y)

	var nearby_spatial_groups = get_parent().get_parent().getExpandedSpatialGroups(spatial_group, ceil(aoe_range / 50))
	var nearby_enemies = []
	for group in nearby_spatial_groups:
		nearby_enemies.append_array(get_parent().get_parent().enemies_spatial_groups[group])

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.global_position - global_position).length()
			if distance < aoe_range:
				enemy.die()

func _on_hit_timer_timeout():
	checkCollisions()

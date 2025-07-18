extends Node2D

var damage
var aoe_range
var duration

var upgrades

func _ready() -> void:
	$ExpirationTimer.start(duration)

	checkCollisions()

func checkCollisions():
	$GPUParticles2D.process_material.emission_ring_radius = aoe_range
	$GPUParticles2D.process_material.emission_ring_inner_radius = aoe_range

	$GPUParticles2D2.process_material.emission_sphere_radius = aoe_range

	var spatial_group = get_parent().getSpatialGroup(global_position.x, global_position.y)

	var nearby_spatial_groups = get_parent().getExpandedSpatialGroups(spatial_group, ceil(aoe_range / get_parent().CELL_WIDTH) + 1)
	var nearby_enemies = []
	for group in nearby_spatial_groups:
		nearby_enemies.append_array(get_parent().enemies_spatial_groups[group])

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.global_position - global_position).length()
			if distance < aoe_range + enemy.size:
				enemy.take_damage(damage * 0.25)

func _on_hit_timer_timeout():
	checkCollisions()

func _on_expiration_timer_timeout():
	queue_free()

extends Node2D

var damage
var radius = 100

func _ready():
	$CPUParticles2D.emitting = true

	var spatial_group = get_parent().getSpatialGroup(global_position.x, global_position.y)

	var nearby_spatial_groups = get_parent().getExpandedSpatialGroups(spatial_group, ceil(radius / get_parent().CELL_WIDTH))
	var nearby_enemies = []
	for group in nearby_spatial_groups:
		nearby_enemies.append_array(get_parent().enemies_spatial_groups[group])

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.global_position - global_position).length()
			if distance < radius:
				enemy.taka_damage(damage)

func _on_cpu_particles_2d_finished():
	queue_free()

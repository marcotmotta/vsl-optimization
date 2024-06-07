extends Node2D

var direction

var length = 350
var range = 30

func _ready():
	$ColorRect.rotation = direction.angle()

	checkCollisions()

func checkCollisions():
	var nearby_enemies = []
	var nearby_groups = []
	for i in range(ceil(length/range) + 1):
		var point = position + (i * range * direction)
		var point_spatial_group = get_parent().getSpatialGroup(point.x, point.y)
		var point_nearby_spatial_groups = get_parent().getExpandedSpatialGroups(point_spatial_group, 1)
		for group in point_nearby_spatial_groups:
			for enemy in get_parent().enemies_spatial_groups[group]:
				if is_instance_valid(enemy):
					var distance = (enemy.global_position - point).length()
					if distance < range:
						if not nearby_enemies.has(enemy): nearby_enemies.append(enemy)

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			enemy.die()

func _on_expiration_timer_timeout():
	queue_free()

func _on_damage_timer_timeout():
	checkCollisions()

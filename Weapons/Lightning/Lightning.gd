extends Node2D

var direction

var damage
var length = 350
var aoe_range = 30

func _ready():
	$ColorRect.rotation = direction.angle()

	checkCollisions()

func checkCollisions():
	var nearby_enemies = []
	for i in range(ceil(length/aoe_range) + 1):
		var point = position + (i * aoe_range * direction)
		var point_spatial_group = get_parent().getSpatialGroup(point.x, point.y)
		var point_nearby_spatial_groups = get_parent().getExpandedSpatialGroups(point_spatial_group, 1)
		for group in point_nearby_spatial_groups:
			for enemy in get_parent().enemies_spatial_groups[group]:
				if is_instance_valid(enemy):
					var distance = (enemy.global_position - point).length()
					if distance < aoe_range:
						if not nearby_enemies.has(enemy): nearby_enemies.append(enemy)

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			enemy.take_damage(damage)

func _on_expiration_timer_timeout():
	queue_free()

func _on_damage_timer_timeout():
	checkCollisions()

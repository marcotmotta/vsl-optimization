extends Node2D

var direction
var speed = 250

var spatial_group = -1

func _ready():
	updateSpatialGroup()

func _process(delta):
	position = position + direction * speed * delta

	updateSpatialGroup()

	checkCollisions()

func checkCollisions():
	var nearby_spatial_groups = get_parent().getExpandedSpatialGroups(spatial_group, 1)
	var nearby_enemies = []
	for group in nearby_spatial_groups:
		nearby_enemies.append_array(get_parent().enemies_spatial_groups[group])
	#print(nearby_enemies)

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.position - position).length()
			if distance < 30:
				enemy.die()

func updateSpatialGroup():
	# FIXME: dunno
	if position.x <= 0 or position.x >= get_parent().MAP_WIDTH or position.y <= 0 or position.y >= get_parent().MAP_HEIGHT:
		get_parent().bullet_spatial_groups[spatial_group].erase(self)
		queue_free()
		return

	var new_spatial_group = get_parent().getSpatialGroup(position.x, position.y)
	if spatial_group < 0:
		spatial_group = new_spatial_group
		get_parent().bullet_spatial_groups[spatial_group].append(self)
	elif new_spatial_group != spatial_group:
		get_parent().bullet_spatial_groups[spatial_group].erase(self)
		spatial_group = new_spatial_group
		get_parent().bullet_spatial_groups[spatial_group].append(self)

func _on_timer_timeout():
	queue_free()

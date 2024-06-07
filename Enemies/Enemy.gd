extends Node2D

var speed = 80
var player

var spatial_group = -1

var size = 13

func _ready():
	randomize()
	player = get_parent().get_node('Player')

func _process(delta):
	position += (player.global_position - global_position).normalized() * speed * delta
	updateSpatialGroup()
	pushNearbyEnemies(delta)

func pushNearbyEnemies(delta):
	var nearby_enemies = get_parent().enemies_spatial_groups[spatial_group]

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.position - position).length()
			if distance < size * 2:
				var direction = (enemy.position - position).normalized()
				enemy.position += direction * enemy.speed * delta

func updateSpatialGroup():
	# FIXME: dunno
	if global_position.x <= max(0, player.global_position.x - 800) or \
	global_position.x >= min(get_parent().MAP_WIDTH, player.global_position.x + 800) or \
	global_position.y <= max(0, player.global_position.y - 650) or \
	global_position.y >= min(get_parent().MAP_HEIGHT, player.global_position.y + 650):
		die()
		return

	var new_spatial_group = get_parent().getSpatialGroup(position.x, position.y)
	if spatial_group < 0:
		spatial_group = new_spatial_group
		get_parent().enemies_spatial_groups[spatial_group].append(self)
	elif new_spatial_group != spatial_group:
		get_parent().enemies_spatial_groups[spatial_group].erase(self)
		spatial_group = new_spatial_group
		get_parent().enemies_spatial_groups[spatial_group].append(self)

func die():
	get_parent().enemies_spatial_groups[spatial_group].erase(self)
	queue_free()

extends Node2D

var star_scene

var direction
var speed = 200

var spatial_group = -1

var damage
var pierce = 2 # amount of enemies it can hit in one go
var aoe_range = 30
var bonus_aoe = 0 # percentage?

# Will hit enemies only once during each step of the movement
var enemies_hit = []

func _ready():
	updateSpatialGroup()
	$Sprite2D.scale *= 1 + (bonus_aoe * 1.3) # scale of model grows bigger than actual aoe
	aoe_range *= 1 + bonus_aoe

	#debug
	#print(aoe_range)
	#$Area2D/CollisionShape2D.shape.radius = aoe_range

func _process(delta):
	position = position + direction * speed * delta
	updateSpatialGroup()
	checkCollisions()

func checkCollisions():
	var nearby_spatial_groups = get_parent().getExpandedSpatialGroups(spatial_group, ceil(aoe_range/50))
	var nearby_enemies = []
	for group in nearby_spatial_groups:
		nearby_enemies.append_array(get_parent().enemies_spatial_groups[group])

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.position - position).length()
			if distance < aoe_range:
				if not enemies_hit.has(enemy):
					enemies_hit.append(enemy)
					enemy.take_damage(damage)

					# check pierce
					pierce -= 1
					if pierce <= 0:
						die()

func updateSpatialGroup():
	if position.x <= 0 or position.x >= get_parent().MAP_WIDTH or position.y <= 0 or position.y >= get_parent().MAP_HEIGHT:
		die()
		return

	var new_spatial_group = get_parent().getSpatialGroup(position.x, position.y)
	if spatial_group < 0:
		spatial_group = new_spatial_group
		get_parent().bullet_spatial_groups[spatial_group].append(self)
	elif new_spatial_group != spatial_group:
		get_parent().bullet_spatial_groups[spatial_group].erase(self)
		spatial_group = new_spatial_group
		get_parent().bullet_spatial_groups[spatial_group].append(self)

func die():
	get_parent().bullet_spatial_groups[spatial_group].erase(self)
	queue_free()

func _on_timer_timeout():
	die()

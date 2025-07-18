extends Node2D

var rang_scene

var direction
var speed
var rate
var duration
var inverted = false

var spatial_group = -1

var damage
var aoe_range = 30
var bonus_aoe = 0 # percentage?

# Will hit enemies only once during each step of the movement
var enemies_hit = []

func _ready():
	updateSpatialGroup()
	#$CPUParticles2D.emission_sphere_radius *= 1 + bonus_aoe
	#$CPUParticles2D.scale_amount_min *= 1 + bonus_aoe
	aoe_range += 1 + bonus_aoe

	rate = speed / duration

func _process(delta):
	if inverted:
		speed += rate * delta
		position = position + (get_parent().get_node('Player').global_position - global_position).normalized() * speed * delta

	else:
		speed = max(speed - (rate * delta), 0)
		position = position + direction * speed * delta

		if speed <= 0:
			inverted = true
			enemies_hit = []

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

	if inverted:
		var distance = (get_parent().get_node('Player').position - position).length()
		if distance < aoe_range:
			die()

func updateSpatialGroup():
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

extends Node2D

var fireball_scene
var explosion_scene = preload("res://Weapons/Explosion/Explosion.tscn")

var direction
var speed = 200

var spatial_group = -1

var damage
var aoe_range = 30
var bounce_count = 0
var has_explosion = false
var bonus_aoe = 0 # percentage?

func _ready():
	updateSpatialGroup()
	$CPUParticles2D.emission_sphere_radius *= 1 + bonus_aoe
	$CPUParticles2D.scale_amount_min *= 1 + bonus_aoe
	aoe_range += 1 + bonus_aoe

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
				print(damage, enemy.health)
				enemy.take_damage(damage)
				if has_explosion: explode()
				if bounce_count > 0: bounce()
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

func _get_random_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var selected_enemy = null
	var selected_enemy_direction = Vector2.ZERO

	if enemies:
		selected_enemy = enemies.pick_random()
		selected_enemy_direction = (selected_enemy.global_position - global_position).normalized()

	return {
		'enemy': selected_enemy,
		'direction': selected_enemy_direction
	}

func bounce():
	bounce_count -= 1
	var selected_enemy = _get_random_enemy()
	var fireball_instance = fireball_scene.instantiate()
	fireball_instance.fireball_scene = fireball_scene
	fireball_instance.global_position = global_position
	fireball_instance.direction = selected_enemy.direction
	fireball_instance.bounce_count = bounce_count
	fireball_instance.has_explosion = has_explosion
	fireball_instance.bonus_aoe = bonus_aoe
	get_parent().add_child(fireball_instance)

func explode():
	var explosion_instance = explosion_scene.instantiate()
	explosion_instance.global_position = global_position
	explosion_instance.damage = damage
	get_parent().add_child(explosion_instance)

func die():
	get_parent().bullet_spatial_groups[spatial_group].erase(self)
	queue_free()

func _on_timer_timeout():
	die()

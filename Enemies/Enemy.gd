extends Node2D

var exp_value: int
var max_health: int
var health: int
var speed: int
var damage: int
var health_modifier: float

var player
var health_bar

var spatial_group = -1

var size = 13

var is_boss = false
var bonus_boss_health = 0

var damage_number_scene = preload("res://DamageNumber/DamageNumber.tscn")

func _ready():
	randomize()
	player = get_parent().get_node('Player')
	health_bar = get_node("HealthBar")

	set_props()
	
	max_health *= 1 + health_modifier

	health = max_health

	# Boss variation:
	if is_boss:
		max_health *= bonus_boss_health * 10
		health = max_health

		size *= 1.5

		damage *= 10

		speed *= 1.2

		$Sprite2D.modulate = '#969696'
		$Sprite2D.scale *= 2

		health_bar.visible = true

func set_props() -> void: # This will be called by the children classes
	pass

func _process(delta):
	position += (player.global_position - global_position).normalized() * speed * delta
	updateSpatialGroup()
	pushNearbyEnemies(delta)

	health_bar.max_value = max_health
	health_bar.value = health

	# Set look direction
	if player.global_position.x < global_position.x:
		$Sprite2D.flip_h = true

	else:
		$Sprite2D.flip_h = false

func pushNearbyEnemies(delta):
	var nearby_enemies = get_parent().enemies_spatial_groups[spatial_group]

	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			var distance = (enemy.position - position).length()
			if distance < size * 2:
				var direction = (enemy.position - position).normalized()
				enemy.position += direction * enemy.speed * delta

func updateSpatialGroup():
	# FIXME: dunno.
	# Despawn enemy if it goes too far from player
	if not is_boss:
		if global_position.x <= max(0, player.global_position.x - 800) or \
		global_position.x >= min(get_parent().MAP_WIDTH, player.global_position.x + 800) or \
		global_position.y <= max(0, player.global_position.y - 650) or \
		global_position.y >= min(get_parent().MAP_HEIGHT, player.global_position.y + 650):
			die(false)
			return

	var new_spatial_group = get_parent().getSpatialGroup(position.x, position.y)
	if spatial_group < 0:
		spatial_group = new_spatial_group
		get_parent().enemies_spatial_groups[spatial_group].append(self)
	elif new_spatial_group != spatial_group:
		get_parent().enemies_spatial_groups[spatial_group].erase(self)
		spatial_group = new_spatial_group
		get_parent().enemies_spatial_groups[spatial_group].append(self)

func take_damage(amount: int):
	var damage_number_instance = damage_number_scene.instantiate()
	damage_number_instance.global_position = global_position
	damage_number_instance.value = amount
	get_parent().add_child(damage_number_instance)

	health = max(health - amount, 0)

	if health <= 0:
		die(true)

func die(give_exp: bool = true):
	if give_exp:
		player.get_exp(exp_value)

	get_parent().enemies_spatial_groups[spatial_group].erase(self)
	queue_free()

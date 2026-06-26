extends Node2D

# =============================================================================
# Inimigo base. Os stats são calculados no _ready a partir de:
#   baseline (WaveData.BASE_*) · ameaça do tier (Main.threat_mult) · arquétipo.
#
# A AMEAÇA é lida no MOMENTO DO SPAWN -> stat TRAVADO (não muda depois). É o que
# dilui o "degrau" de dificuldade na rotatividade dos spawns (ver SCALING_DESIGN.md).
# =============================================================================

# Arquétipo (a subclasse define em set_props). Multiplicadores em WaveData.archetypes.
var archetype_name = "Basic"

# Flags de boss — setadas pelo SPAWNER (Main) ANTES do add_child, para o _ready vê-las.
var is_boss = false
var is_final_boss = false
var boss_k = 0          # HP do boss = BASE_HP · ameaça · boss_k
var boss_drop_scene

var exp_value: int
var max_health: int
var health: int
var speed: int
var damage: int

var player
var health_bar

var spatial_group = -1

var size = 13

var damage_number_scene = preload("res://DamageNumber/DamageNumber.tscn")

func _ready():
	randomize()
	player = get_parent().get_node('Player')
	health_bar = get_node("HealthBar")

	set_props() # a subclasse define o archetype_name (e, opcionalmente, o size)

	# Ameaça TRAVADA no spawn: lê o relógio do Main agora e não muda mais.
	var threat: float = get_parent().threat_mult
	var arch: Dictionary = WaveData.archetypes[archetype_name]

	# Velocidade NÃO escala com a ameaça (é eixo de arquétipo apenas); senão os
	# inimigos alcançariam o player só pela passagem do tempo, virando outro eixo
	# de dificuldade fora do nosso controle.
	speed = int(round(WaveData.BASE_SPEED * arch.speed_mult))
	damage = int(round(WaveData.BASE_DAMAGE * threat * arch.dmg_mult))

	if is_boss:
		# Boss: HP ignora o hp_mult do arquétipo e usa a constante K.
		max_health = int(round(WaveData.BASE_HP * threat * boss_k))

		damage *= 10
		speed = int(round(speed * 1.15))
		size = int(round(size * 1.5))

		$Sprite2D.modulate = '#969696'
		$Sprite2D.scale *= 2

		health_bar.visible = true
		health_bar.position.y = 40

		boss_drop_scene = load("res://Drops/BossDrop.tscn")
	else:
		max_health = int(round(WaveData.BASE_HP * threat * arch.hp_mult))

	health = max_health

	# XP por kill ∝ HP^0.X (botão da espiral, a≈0.X — ver SCALING_DESIGN.md §5).
	# Dividir por BASE_HP mantém "1 XP" para o inimigo base no tier 0.
	exp_value = max(1, int(round(pow(float(max_health) / WaveData.BASE_HP, 0.3))))

func set_props() -> void:
	# Sobrescrito pelas subclasses (Enemy1/2/3/...) para declarar o arquétipo.
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

	if is_boss:
		var boss_drop_instance = boss_drop_scene.instantiate()
		boss_drop_instance.global_position = global_position

		get_parent().add_child(boss_drop_instance)

	# Boss FINAL derrotado -> VITÓRIA.
	if is_final_boss:
		get_parent().on_final_boss_defeated()

	get_parent().enemies_spatial_groups[spatial_group].erase(self)
	queue_free()

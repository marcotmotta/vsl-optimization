extends Node2D

# =============================================================================
# Main — orquestra o jogo: grade espacial, spawn de inimigos e RELÓGIO DE RUN.
#
# RELÓGIO DE RUN (ver SCALING_DESIGN.md, modelo de dois relógios):
#   run_time     acumula o tempo de jogo (pausa junto com a árvore no level-up).
#   current_tier = run_time / TIER_INTERVAL  -> sobe em degraus.
#   threat_mult  = GROWTH ^ current_tier      -> multiplicador de AMEAÇA.
# Os inimigos leem threat_mult no _ready (stat TRAVADO no spawn).
# =============================================================================

const MAP_WIDTH = 18000
const MAP_HEIGHT = 18000
const CELLS_PER_ROW = 360
const CELLS_PER_COL = 360
# cell size: 50
const CELL_WIDTH = MAP_WIDTH / CELLS_PER_ROW
const CELL_HEIGHT = MAP_HEIGHT / CELLS_PER_COL
const TOTAL_CELLS = CELLS_PER_ROW * CELLS_PER_COL + 1

# Multiplicador de densidade durante a luta do boss final (ramp de clímax).
const FINAL_BOSS_DENSITY_RAMP = 1.5

var enemy_scenes = {
	'Enemy1': preload("res://Enemies/Enemy1/Enemy1.tscn"),
	'Enemy2': preload("res://Enemies/Enemy2/Enemy2.tscn"),
	'Enemy3': preload("res://Enemies/Enemy3/Enemy3.tscn")
}

var enemies_spatial_groups = []
var bullet_spatial_groups = []

var player

# Config central de scaling (constantes, arquétipos, cronograma).
var WaveParams = WaveData.new()

# --- Relógio de run / ameaça -------------------------------------------------
var run_time: float = 0.0
var current_tier: int = 0
var threat_mult: float = 1.0

# --- Estado do boss final ----------------------------------------------------
var final_boss_active: bool = false
var final_boss

func _ready():
	randomize()

	player = get_node("Player")

	# create spatial groups
	for i in range(TOTAL_CELLS):
		enemies_spatial_groups.append([])
		bullet_spatial_groups.append([])

func _process(delta):
	# Avança o relógio de run e recalcula tier/ameaça.
	# Durante o level-up a árvore fica pausada, então este _process não roda e o
	# tempo de "pensar" no upgrade não conta para a ameaça — de propósito.
	run_time += delta
	current_tier = int(run_time / WaveParams.TIER_INTERVAL)
	threat_mult = pow(WaveParams.GROWTH, current_tier)

func getSpatialGroup(x, y):
	var xIndex = int(x / CELL_WIDTH)
	var yIndex = int(y / CELL_HEIGHT)

	return xIndex + yIndex * CELLS_PER_ROW

func getExpandedSpatialGroups(spatial_group, radius = 1):
	var spatial_groups = []

	for y in range(radius + 1):
		for x in range(radius + 1):
			var new_cell
			new_cell = spatial_group + (y * CELLS_PER_ROW) + x
			if new_cell >= 0 and new_cell < TOTAL_CELLS and not spatial_groups.has(new_cell) : spatial_groups.append(new_cell)
			new_cell = spatial_group + (y * CELLS_PER_ROW) - x
			if new_cell >= 0 and new_cell < TOTAL_CELLS and not spatial_groups.has(new_cell) : spatial_groups.append(new_cell)
			new_cell = spatial_group - (y * CELLS_PER_ROW) + x
			if new_cell >= 0 and new_cell < TOTAL_CELLS and not spatial_groups.has(new_cell) : spatial_groups.append(new_cell)
			new_cell = spatial_group - (y * CELLS_PER_ROW) - x
			if new_cell >= 0 and new_cell < TOTAL_CELLS and not spatial_groups.has(new_cell) : spatial_groups.append(new_cell)

	return spatial_groups

# --- Spawn de inimigos -------------------------------------------------------

# Escolhe um ponto de spawn ao redor do player, fora de um raio mínimo (para não
# nascer em cima dele) e dentro dos limites do mapa.
func _find_spawn_point() -> Vector2:
	while true:
		var p = Vector2(
			randi_range(int(player.global_position.x) - 750, int(player.global_position.x) + 750),
			randi_range(int(player.global_position.y) - 600, int(player.global_position.y) + 600)
		)
		if (p - player.global_position).length() > 550 and p.x > 0 and p.x < MAP_WIDTH and p.y > 0 and p.y < MAP_HEIGHT:
			return p
	return Vector2.ZERO # inalcançável (satisfaz o analisador estático)

# Instancia um inimigo de um arquétipo e o posiciona, mas NÃO o adiciona à árvore.
# O chamador adiciona com add_child() — assim dá pra setar flags (ex.: is_boss)
# ANTES do _ready do inimigo, que é quando os stats são travados no spawn.
func _make_enemy(archetype_name: String) -> Node:
	var arch = WaveParams.archetypes[archetype_name]
	var enemy = enemy_scenes[arch.scene_key].instantiate()
	enemy.archetype_name = archetype_name
	enemy.global_position = _find_spawn_point()
	return enemy

func _on_spawn_timer_timeout():
	var current_enemies = get_tree().get_nodes_in_group('enemy').size()

	# Teto rígido: não spawna nada se o limite foi atingido.
	if current_enemies >= WaveParams.MAX_ENEMIES:
		return

	# Linha do cronograma vigente para o tier atual (densidade + pool de tipos).
	var row = WaveParams.get_schedule_row(current_tier)

	# Densidade-alvo (com ramp durante o boss final), limitada pelo teto rígido.
	var target_density = row.density
	if final_boss_active:
		target_density = int(target_density * FINAL_BOSS_DENSITY_RAMP)
	target_density = min(target_density, WaveParams.MAX_ENEMIES)

	if current_enemies >= target_density:
		# Pool cheio: trickle de 1 inimigo (mantém a composição viva).
		add_child(_make_enemy(row.pool.pick_random()))
	else:
		# Abaixo do piso: preenche de uma vez até a densidade-alvo.
		for i in range(target_density - current_enemies):
			add_child(_make_enemy(row.pool.pick_random()))

# --- Bosses ------------------------------------------------------------------

# Arquétipo do mini-boss (placeholder: alterna conforme avança).
func _pick_boss_archetype(level: int) -> String:
	var names = ["Tank", "Fast", "Basic"]
	return names[(level / WaveParams.MINIBOSS_EVERY - 1) % names.size()]

# Mini-boss: disparado pelo NÍVEL (a cada MINIBOSS_EVERY). HP via MINIBOSS_K.
func spawn_miniboss(level: int):
	var boss = _make_enemy(_pick_boss_archetype(level))
	boss.is_boss = true
	boss.boss_k = WaveParams.MINIBOSS_K
	add_child(boss) # agora o _ready vê as flags e calcula os stats de boss

# Boss FINAL: disparado no marco de vitória (WIN_LEVEL). HP via FINAL_BOSS_K.
# As waves continuam (o spawner é independente) e a densidade ganha ramp.
func spawn_final_boss():
	# Reusa uma cena de inimigo existente; visual/comportamento próprio fica pra depois.
	var boss = _make_enemy("Tank")
	boss.is_boss = true
	boss.is_final_boss = true
	boss.boss_k = WaveParams.FINAL_BOSS_K
	final_boss = boss
	final_boss_active = true
	add_child(boss)

# Chamado pelo boss final ao morrer (Enemy.die). VITÓRIA.
func on_final_boss_defeated():
	final_boss_active = false
	# STUB de vitória — uma tela final dedicada fica pra depois (ver SCALING_DESIGN.md).
	get_tree().paused = true
	player.get_node("CanvasLayer/LevelLabel").text = "VITORIA!\nBoss final derrotado."

# --- Debug -------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("f1"):
		# debug: pula 1 tier de ameaça (avança o relógio em um intervalo).
		run_time += WaveParams.TIER_INTERVAL

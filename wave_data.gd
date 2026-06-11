extends Resource
class_name WaveData # Makes this a global type

# =============================================================================
# CONFIG CENTRAL DE SCALING  (ver SCALING_DESIGN.md)
#
# Modelo de DOIS RELÓGIOS:
#   - TEMPO  -> dirige a AMEAÇA (dificuldade): stats, densidade e composição.
#   - NÍVEL  -> dirige o PROGRESSO do player (upgrades + gatilho do boss final).
#
# A ameaça cresce em DEGRAUS de "tier". A cada TIER_INTERVAL segundos o tier
# sobe 1, e o multiplicador de ameaça é GROWTH ^ tier (exponencial).
# Os stats são travados no SPAWN de cada inimigo (sem "cliff" retroativo).
#
# Para escalonar o jogo, edite os dados deste arquivo — nenhuma lógica precisa
# mudar (modelo data-driven).
# =============================================================================

# --- Curva de ameaça (PROVISÓRIA; rever junto com a DPS/upgrades) ---
const GROWTH: float = 1.1           # multiplicador de força por tier (+10%/degrau)
const TIER_INTERVAL: float = 90.0   # segundos por tier

# --- Stats baseline (a que os multiplicadores de arquétipo se aplicam) ---
const BASE_HP: int = 10
const BASE_SPEED: int = 60
const BASE_DAMAGE: int = 10

# --- Progressão / final ---
const WIN_LEVEL: int = 100      # nível que dispara o BOSS FINAL (vitória)
const MINIBOSS_EVERY: int = 8   # mini-boss a cada N níveis

# --- Tankiness dos bosses: HP = BASE_HP * ameaça * K ---
const MINIBOSS_K: int = 25
const FINAL_BOSS_K: int = 80

# Teto rígido de inimigos simultâneos (performance).
@export var MAX_ENEMIES: int = 200

# --- Arquétipos: multiplicadores RELATIVOS ao baseline ---------------------
# Adicionar inimigo novo = adicionar uma entrada aqui (e a cena em Main.enemy_scenes).
# "scene_key" casa com as chaves de Main.enemy_scenes.
# Obs.: a velocidade NÃO escala com a ameaça — só com o arquétipo (ver Enemy.gd).
const archetypes = {
	"Basic": { "scene_key": "Enemy1", "hp_mult": 1.0, "speed_mult": 1.0,  "dmg_mult": 1.0 },
	"Tank":  { "scene_key": "Enemy2", "hp_mult": 2.0, "speed_mult": 1.0,  "dmg_mult": 1.0 },
	"Fast":  { "scene_key": "Enemy3", "hp_mult": 1.5, "speed_mult": 1.25, "dmg_mult": 1.0 },
}

# --- Cronograma de ameaça (composição + densidade por tier) ----------------
# Indexado por tier. O spawner usa a linha de MAIOR "tier" <= tier atual.
#   density = piso de inimigos que o spawner tenta manter (limitado por MAX_ENEMIES).
#   pool    = arquétipos que podem aparecer nesse tier.
# Adicionar dificuldade = estender estas linhas (RASCUNHO — ajustar à vontade).
const schedule = [
	{ "tier": 0, "density": 10, "pool": ["Basic"] },
	{ "tier": 1, "density": 25, "pool": ["Basic"] },
	{ "tier": 2, "density": 40, "pool": ["Basic", "Tank"] },
	{ "tier": 3, "density": 50, "pool": ["Basic", "Tank"] },
	{ "tier": 4, "density": 60, "pool": ["Basic", "Tank", "Fast"] },
	{ "tier": 5, "density": 70, "pool": ["Basic", "Tank", "Fast"] },
	{ "tier": 6, "density": 80, "pool": ["Basic", "Tank", "Fast"] },
]

# Retorna a linha do cronograma vigente para um dado tier
# (a de maior "tier" que ainda é <= ao tier atual). Assume schedule ordenado.
func get_schedule_row(tier: int) -> Dictionary:
	var row = schedule[0]
	for r in schedule:
		if r.tier <= tier:
			row = r
		else:
			break
	return row

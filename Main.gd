extends Node2D

const MAP_WIDTH = 3000
const MAP_HEIGHT = 3000
const CELLS_PER_ROW = 60
const CELLS_PER_COL = 60
# cell size: 50
const CELL_WIDTH = MAP_WIDTH / CELLS_PER_ROW
const CELL_HEIGHT = MAP_HEIGHT / CELLS_PER_COL
const TOTAL_CELLS = CELLS_PER_ROW * CELLS_PER_COL + 1

var enemy_scene = preload("res://Enemies/Enemy.tscn")

var enemies_spatial_groups = []
var bullet_spatial_groups = []

var player

# level params
const MAX_ENEMIES = 200
var current_max_enemies = 10

func _ready():
	randomize()
	
	player = get_node("Player")

	# create spatial groups
	for i in range(TOTAL_CELLS):
		enemies_spatial_groups.append([])
		bullet_spatial_groups.append([])

func _process(delta):
	#print('FPS ', str(Engine.get_frames_per_second()))
	#print('enemies', ' ', get_tree().get_nodes_in_group('enemy').size())
	#print('ALL ', get_tree().get_node_count())
	pass

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

# spawn enemies FIXME: placeholder
func _on_spawn_timer_timeout():
	var current_enemies = get_tree().get_nodes_in_group('enemy').size()

	# hard limit
	# does not spawn any enemies if limit reached
	if current_enemies >= MAX_ENEMIES: return

	# level limit
	# spawn 1 enemy if pool is full
	print(current_enemies, current_enemies >= current_max_enemies)
	if current_enemies >= current_max_enemies:
		while(true):
			# choose spawn point
			var spawn_point = Vector2(randi_range(player.global_position.x - 750, player.global_position.x + 750), randi_range(player.global_position.y - 600, player.global_position.y + 600))
			if ((spawn_point - player.global_position).length() > 500) and spawn_point.x > 0 and spawn_point.x < MAP_WIDTH and spawn_point.y > 0 and spawn_point.y < MAP_HEIGHT:
				var enemy_instance = enemy_scene.instantiate()
				enemy_instance.global_position = spawn_point
				add_child(enemy_instance)
				break
	else:
		var available_slots = current_max_enemies - current_enemies
		for i in range(available_slots):
			while(true):
				# choose spawn point
				var spawn_point = Vector2(randi_range(player.global_position.x - 750, player.global_position.x + 750), randi_range(player.global_position.y - 600, player.global_position.y + 600))
				if ((spawn_point - player.global_position).length() > 500) and spawn_point.x > 0 and spawn_point.x < MAP_WIDTH and spawn_point.y > 0 and spawn_point.y < MAP_HEIGHT:
					var enemy_instance = enemy_scene.instantiate()
					enemy_instance.global_position = spawn_point
					add_child(enemy_instance)
					break

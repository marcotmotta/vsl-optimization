extends Resource
class_name WaveData # Makes this a global type

@export var MAX_ENEMIES: int = 200

# Spawn a boss each round multiple by 8.
# 8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96, etc.
#
@export var bosses: Dictionary = {
	8: 'Enemy1',
	16: 'Enemy2',
	'default': 'Enemy1'
}

@export var waves: Dictionary = {
	1: { # Level 1
		'min_enemies': 10,
		'enemy_types': ['Enemy1']
	},
	2: { # Level 5
		'min_enemies': 15,
		'enemy_types': ['Enemy2']
	},
	3: { # Level 10
		'min_enemies': 30,
		'enemy_types': ['Enemy1', 'Enemy2']
	},
	4: { # Level 15
		'min_enemies': 50,
		'enemy_types': ['Enemy1', 'Enemy2']
	},
	5: { # Level 20
		'min_enemies': 80,
		'enemy_types': ['Enemy1']
	},
	6: { # Level 25
		'min_enemies': 80,
		'enemy_types': ['Enemy1', 'Enemy2']
	}
}

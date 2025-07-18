extends Resource
class_name WaveData # Makes this a global type

@export var MAX_ENEMIES: int = 200

@export var waves: Dictionary = {
	1: { # Level 1
		'min_enemies': 10,
		'enemy_types': ['Enemy1']
	},
	2: { # Level 5
		'min_enemies': 15,
		'enemy_types': ['Enemy1', 'Enemy2']
	},
	3: { # Level 10
		'min_enemies': 20,
		'enemy_types': ['Enemy1', 'Enemy2']
	},
	4: { # Level 15
		'min_enemies': 25,
		'enemy_types': ['Enemy1', 'Enemy2']
	},
	5: { # Level 20
		'min_enemies': 30,
		'enemy_types': ['Enemy1', 'Enemy2']
	},
	6: { # Level 25
		'min_enemies': 35,
		'enemy_types': ['Enemy1', 'Enemy2']
	}
}

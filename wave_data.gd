extends Resource
class_name WaveData # Makes this a global type

@export var MAX_ENEMIES: int = 200

@export var waves: Dictionary = {
	1: {
		'min_enemies': 10
	},
	2: {
		'min_enemies': 15
	},
	3: {
		'min_enemies': 20
	},
	4: {
		'min_enemies': 25
	},
	5: {
		'min_enemies': 30
	},
	6: {
		'min_enemies': 35
	}
}

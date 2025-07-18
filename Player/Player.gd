extends CharacterBody2D

# Abilities
var abilities = [
	{
		"name": "Fireball",
		"rarity": 8, # Higher value = more common. Values: 8, 5, 3, 2, 1
		"controller": preload("res://Weapons/Fireball/FireballController.tscn"),
		"upgrades": [
			{
				"name": "count",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "damage",
				"max_level": 2,
				"rarity": 8,
			}
		]
	},
	{
		"name": "Lightning",
		"rarity": 8,
		"controller": preload("res://Weapons/Lightning/LightningController.tscn"),
		"upgrades": [
			{
				"name": "count",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "damage",
				"max_level": 2,
				"rarity": 8,
			}
		]
	},
	{
		"name": "Poison",
		"rarity": 8,
		"controller": preload("res://Weapons/Poison/PoisonController.tscn"),
		"upgrades": [
			{
				"name": "count",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "area",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "duration",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "damage",
				"max_level": 2,
				"rarity": 8,
			}
		]
	},
	{
		"name": "Area",
		"rarity": 8,
		"controller": preload("res://Weapons/AreaController.tscn"),
		"upgrades": [
			{
				"name": "area",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "damage",
				"max_level": 2,
				"rarity": 8,
			}
		]
	},
	{
		"name": "Rang",
		"rarity": 8,
		"controller": preload("res://Weapons/Rang/RangController.tscn"),
		"upgrades": [
			{
				"name": "count",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "range",
				"max_level": 2,
				"rarity": 8,
			},
			{
				"name": "damage",
				"max_level": 2,
				"rarity": 8,
			}
		]
	}
]

# {"Fireball": {"unlocked": true, "upgrades": {"count": 2, "damage": 1}}}
var current_abilities = {}

# Level params
var current_level = 1
var current_exp = 0

var spatial_group = 0

var speed = 100

func move(_delta):
	var input_direction = Input.get_vector("a", "d", "w", "s").normalized()

	velocity = input_direction * speed
	move_and_slide()

func _process(delta):
	# UI
	$CanvasLayer/LevelLabel.text = 'current level: ' + str(current_level) +\
	'\ncurrent cycle: ' + str(get_parent().current_cycle)

	# Movement
	move(delta)
	spatial_group = get_parent().getSpatialGroup(position.x, position.y)

# Abilties utils {{{
func has_base(ability_name):
	return current_abilities.get(ability_name, {}).get("unlocked", false)

func get_upgrade_level(ability_name, upgrade_name):
	return current_abilities.get(ability_name, {}).get("upgrades", {}).get(upgrade_name, 0)

func unlock_base(ability):
	current_abilities.get_or_add(ability.name, {"unlocked": true, "upgrades": {}})

	var ability_controller_instance = ability.controller.instantiate()
	add_child(ability_controller_instance)
	
	end_upgrade_logic()

func add_upgrade(ability, upgrade):
	if ability.name in current_abilities:
		var current_upgrade_level = current_abilities[ability.name]["upgrades"].get(upgrade.name, 0)
		current_abilities[ability.name]["upgrades"][upgrade.name] = current_upgrade_level + 1

	end_upgrade_logic()
# }}}

# Level up {{{
func get_upgrade_choices(num_choices = 3):
	var pool = []
	var weights = []

	# Base abilities:
	for ability in abilities:
		if not has_base(ability.name):
			pool.append({"type": "base", "ability": ability})
			weights.append(ability.rarity)

	# Upgrades:
	for ability in abilities:
		if has_base(ability.name):
			for upgrade in ability.upgrades:
				var current_upgrade_level = get_upgrade_level(ability.name, upgrade.name)
				if current_upgrade_level < upgrade.max_level:
					pool.append({"type": "upgrade", "ability": ability, "upgrade": upgrade})
					weights.append(upgrade.rarity)

	if pool.size() == 0:
		return []

	# Select unique items based on weights
	var selected = []
	var temp_pool = pool.duplicate()
	var temp_weights = weights.duplicate()

	for i in range(min(num_choices, temp_pool.size())):
		var index = weighted_random_index(temp_weights)
		selected.append(temp_pool[index])
		temp_pool.remove_at(index)
		temp_weights.remove_at(index)

	return selected

# This is similar to the choices function in python.
# I dont fully understand this, but it chooses indexes based on weight values.
func weighted_random_index(weights: Array) -> int:
	var total_weight = 0
	for w in weights:
		total_weight += w

	var r = randf() * total_weight
	var cumulative = 0

	for i in range(weights.size()):
		cumulative += weights[i]
		if r <= cumulative:
			return i

	return weights.size() - 1 # Fallback (should never happen)

func set_upgrade_buttons(upgrade_choices):
	for i in upgrade_choices.size():
		var upgrade_button = $CanvasLayer/UpgradeButtons/VBoxContainer.get_child(i)

		upgrade_button.text = upgrade_choices[i].name
		upgrade_button.pressed.connect(upgrade_choices[i].callable)
		upgrade_button.visible = true

	$CanvasLayer/UpgradeButtons.visible = true
	get_tree().paused = true

# This cleans the buttons signals after the player selects an upgrade
func end_upgrade_logic():
	var upgrade_buttons = $CanvasLayer/UpgradeButtons/VBoxContainer.get_children()

	for upgrade_button in upgrade_buttons:
		for connection in upgrade_button.pressed.get_connections():
			upgrade_button.pressed.disconnect(connection.callable)
			upgrade_button.visible = false

	$CanvasLayer/UpgradeButtons.visible = false
	get_tree().paused = false

func level_up():
	current_level += 1

	if current_level % 5 == 0:
		get_parent().go_to_next_level()

	var upgrade_choices = []
	var choices = get_upgrade_choices() # Get new upgrade choices

	if choices: # There are available upgrades on the pool
		for choice in choices:
			var upgrade_info = {}

			if choice.type == "base":
				upgrade_info.name = choice.ability.name
				upgrade_info.callable = Callable(self, "unlock_base").bind(choice.ability)

			else:
				upgrade_info.name = choice.ability.name + choice.upgrade.name
				upgrade_info.callable = Callable(self, "add_upgrade").bind(choice.ability, choice.upgrade)

			upgrade_choices.append(upgrade_info)

		set_upgrade_buttons(upgrade_choices)

	else: # Already got all upgrades
		pass

func get_exp(amount: int):
	# Needed exp for level up formula
	var needed_exp = 5 + current_level * 3

	current_exp = min(current_exp + amount, needed_exp)

	if current_exp >= needed_exp:
		current_exp = 0
		level_up()
# }}}

# debug
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("f2"):
		# placeholder for the player choosing an upgrade
		level_up()

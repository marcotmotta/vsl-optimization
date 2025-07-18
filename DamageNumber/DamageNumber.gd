extends Node2D

var value = 0

func _ready() -> void:
	$Label.label_settings = $Label.label_settings.duplicate()

	value = ceil(value)

	if randi() % 2: # 50% chance
		value += randi() % 3

	$Label.text = str(value)

	if value >= 100:
		$Label.label_settings.font_color = '#ffd700'

	elif value >= 30:
		$Label.label_settings.font_color = '#00d3d3'

	else:
		$Label.label_settings.font_color = '#ffffff'

	$AnimationPlayer.play("number")

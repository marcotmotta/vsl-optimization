extends "res://Enemies/Enemy.gd"

# Stats vêm do baseline · ameaça · arquétipo (ver Enemy.gd / WaveData.archetypes).
func set_props() -> void:
	archetype_name = "Fast"
	size = 10 # menor que o padrão (raio de empurrão)

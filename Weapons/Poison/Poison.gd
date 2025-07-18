extends Node2D

var poison_area_scene = preload("res://Weapons/Poison/PoisonArea.tscn")

var target_position
var direction

var time = 0

var damage
var aoe_range
var duration

func _ready():
	randomize()
	
	$AnimationPlayer.play(str(randi_range(1, 2)))

func _process(delta):
	var invert = -1 if direction.x > 0 else 1

	$Sprite2D.position = _quadratic_bezier(Vector2.ZERO, ((target_position - position) / 2).rotated(deg_to_rad(45 * invert)), target_position - position, time)
	time += delta / 1.2 # This is the time the poison takes to get to the target point
	if time > 1:
		var poison_area_instance = poison_area_scene.instantiate()
		poison_area_instance.global_position = $Sprite2D.global_position
		poison_area_instance.damage = damage
		poison_area_instance.aoe_range = aoe_range
		poison_area_instance.duration = duration
		get_parent().add_child(poison_area_instance)
		queue_free()

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r

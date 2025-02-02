extends Node2D

var poison_scene = preload("res://Weapons/Poison/Poison.tscn")

var p2
var direction

var time = 0

func _ready():
	randomize()
	
	$AnimationPlayer.play(str(randi_range(1, 2)))

func _process(delta):
	var invert = -1 if direction.x > 0 else 1

	$Sprite2D.position = _quadratic_bezier(Vector2.ZERO, ((p2 - position) / 2).rotated(deg_to_rad(45 * invert)), p2 - position, time)
	time += delta / 1.5
	if time > 1:
		var poison_instance = poison_scene.instantiate()
		poison_instance.global_position = $Sprite2D.global_position
		get_parent().add_child(poison_instance)
		queue_free()

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r

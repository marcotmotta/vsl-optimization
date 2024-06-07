extends Node2D

var explosion_scene = preload("res://Weapons/Explosion/Explosion.tscn")

var p2
var direction

var time = 0

func _process(delta):
	var invert = -1 if direction.x > 0 else 1
	
	print(p2 - position)

	$Sprite2D.position = _quadratic_bezier(Vector2.ZERO, ((p2 - position) / 2).rotated(deg_to_rad(45 * invert)), p2 - position, time)
	time += delta / 1.5
	if time > 1:
		var explosion_instance = explosion_scene.instantiate()
		explosion_instance.global_position = $Sprite2D.global_position
		get_parent().add_child(explosion_instance)
		queue_free()

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r

extends CharacterBody2D

var spatial_group = 0

var speed = 300

func move(delta):
	var input_direction = Input.get_vector("a", "d", "w", "s").normalized()

	velocity = input_direction * speed
	move_and_slide()

func _process(delta):
	move(delta)
	spatial_group = get_parent().getSpatialGroup(position.x, position.y)

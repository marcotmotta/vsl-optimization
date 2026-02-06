extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('player'):
		body.get_special_upgrade()
		queue_free()

func _on_activation_timer_timeout() -> void:
	$CollisionShape2D.disabled = false

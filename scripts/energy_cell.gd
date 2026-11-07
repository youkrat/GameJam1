extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		GameManager.add_energy_cell()
		#pick up energy cell by freeing it from queue 
		queue_free()

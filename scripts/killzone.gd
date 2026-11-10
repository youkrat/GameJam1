extends Area2D



var player_died = false

func _enter_tree() -> void:
	monitoring = false
	
func _ready() -> void:
	# Give the level time to place the player and update physics.
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Start detecting bodies once setup is complete.
	set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		body.die()



	
"""#Removes the player from current scene
func _on_body_entered(body: Node2D) -> void:
	#Only react to the player
	if body != GameManager.player or player_died:
		return 
		
	player_died = true 
	print("You died! Player position: ", body.global_position)
	Engine.time_scale = 0.5
#	body.get_node("CollisionShape2D").queue_free()
	player_died = false
	timer.start()

#Reloads the current scene
func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	await get_tree().physics_frame
	GameManager.load_level(GameManager.current_level)"""

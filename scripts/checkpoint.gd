extends Area2D

class_name Checkpoint

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var activated = false

func activate():
	GameManager.current_checkpoint = self
	activated = true 
	animated_sprite_2d.play("default")
	

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController and !activated:
		print("Checkpoint entered")
		activate()

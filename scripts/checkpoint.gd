extends AnimatedSprite2D

class_name Checkpoint
@export var spawn_point = false
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var activated = false


func activate():
	GameManager.current_checkpoint = self
	activated = true 
	animated_sprite_2d.play("default")
	


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent() is PlayerController and !activated:
		print("Checkpoint entered")
		activate()


func _on_checkpoint_body_entered(body: Node2D) -> void:
	if body is PlayerController and !activated:
		print("Checkpoint entered")
		activate()

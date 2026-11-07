extends CharacterBody2D
class_name PlayerController

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var camera: Camera2D

const SPEED = 300.0
const JUMP_VELOCITY = -850.0

var is_rolling = false

func _ready() -> void:
	animated_sprite_2d.sprite_frames.set_animation_loop("roll", false)
	
func _physics_process(delta: float) -> void:
		
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.play("jump")
	
	#Play animations
	elif Input.is_action_just_pressed("down") and is_on_floor():
		animated_sprite_2d.play("roll")
	elif animated_sprite_2d.animation != "roll" or not animated_sprite_2d.is_playing():
		if velocity.x > 1 or velocity.x < -1:
			animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("idle")
	

	# Handle jump.
	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

		
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	is_rolling = animated_sprite_2d.animation == "roll" and animated_sprite_2d.is_playing()
	
	#$CollisionShape2D.set_deferred("disabled", is_rolling)
	#$RollCollision.set_deferred("disabled", not is_rolling)
	
	move_and_slide()
	
	#Flip the sprite 
	if direction == 1.0:
		animated_sprite_2d.flip_h = false
		
	elif direction == -1.0:
		animated_sprite_2d.flip_h = true 
		
		
func teleport_to_location(new_location):
	camera.position_smoothing_enabled = false
	position = new_location
	#wait for a physics frame to give the camera time to move
	await get_tree().physics_frame
	camera.position_smoothing_enabled = true

extends CharacterBody2D
class_name PlayerController

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_area_start_x: float = absf(attack_area.position.x)
@onready var sprite_start_position: Vector2 = animated_sprite_2d.position

@export var camera: Camera2D
#Visual adjustment for the unflipped left-facing attack artwork

@export var attack_visual_offset := Vector2(-3.0, 0.0)

const SPEED = 200
const JUMP_VELOCITY = -450.0
const ATTACK_BRAKING = 1400
const ATTACK_ACTIVE_FRAME = 1

var attacking = false
var is_rolling = false
var is_dead = false
var facing_direction = 1.0
var hit_targets: Array[Node] = []

func _ready() -> void:
	GameManager.player = self
	animated_sprite_2d.sprite_frames.set_animation_loop("roll", false)
	animated_sprite_2d.sprite_frames.set_animation_loop("attack", false)
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	_set_facing(facing_direction)
	
func _process(delta):
	if Input.is_action_just_pressed("attack"):
		attack()
		

func attack() -> void:
	if attacking or is_dead or is_rolling:
		return

	attacking = true
	hit_targets.clear()
	animated_sprite_2d.position = sprite_start_position + Vector2(
		attack_visual_offset.x * -facing_direction,
		attack_visual_offset.y
	)
	# Restart from frame zero, including consecutive attacks.
	animated_sprite_2d.stop()
	animated_sprite_2d.play("attack")

func _on_animation_finished() -> void:
	if animated_sprite_2d.animation == "attack":
		_cancel_attack()

func _cancel_attack() -> void:
	attacking = false
	hit_targets.clear()
	animated_sprite_2d.position = sprite_start_position
	
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity remains active throughout the attack.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("left", "right")
	is_rolling = animated_sprite_2d.animation == "roll" and animated_sprite_2d.is_playing()

	if not attacking and direction != 0.0:
		_set_facing(direction)

	if Input.is_action_just_pressed("attack"):
		attack()

	if attacking:
		# Commit to the swing and ease horizontal movement to a stop.
		velocity.x = move_toward(velocity.x, 0.0, ATTACK_BRAKING * delta)
	else:
		if Input.is_action_just_pressed("up") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	if attacking:
		# The middle frame is the extended thrust; frame indices start at zero.
		if animated_sprite_2d.frame == ATTACK_ACTIVE_FRAME:
			_check_attack_hits()
	else:
		_update_movement_animation()

func _set_facing(direction: float) -> void:
	facing_direction = signf(direction)
	# Your skeleton artwork faces left before flipping.
	animated_sprite_2d.flip_h = facing_direction > 0.0
	attack_area.position.x = attack_area_start_x * facing_direction

func _check_attack_hits() -> void:
	for area in attack_area.get_overlapping_areas():
		var target = area.get_parent()
		if hit_targets.has(target):
			continue
		hit_targets.append(target)
		print("Hit: ", target.name)

func _update_movement_animation() -> void:
	if not is_on_floor():
		animated_sprite_2d.play("jump")
	elif Input.is_action_just_pressed("down"):
		animated_sprite_2d.play("roll")
	elif animated_sprite_2d.animation != "roll" or not animated_sprite_2d.is_playing():
		if absf(velocity.x) > 1.0:
			animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("idle")
			
	
func teleport_to_location(new_location):
	global_position = new_location
	velocity = Vector2.ZERO
	is_rolling = false
	attacking = false
	animated_sprite_2d.play("idle")
	camera.reset_smoothing()
	camera.force_update_scroll()

#Added to prevent simultaneous mob and boundary hits from starting multiple respawns
func die() -> void:
	if is_dead:
		return
	is_dead = true
	_cancel_attack()
	#Move after the current physics signal is finished
	GameManager.respawn_player.call_deferred()

extends CharacterBody2D

@export_range(1, 100) var max_health: int = 3
@export var detection_range: float = 300.0
@export var attack_range: float = 70.0
@export var max_attack_height: float = 45.0
@export var chase_speed: float = 65.0
@export var acceleration: float = 600.0
@export var attack_cooldown: float = 0.8
@export_enum("attack1", "attack2") var attack_animation: String = "attack1"
@export_range(0, 6) var active_start_frame: int = 4
@export_range(0, 6) var active_end_frame: int = 5
@export var stop_at_edges: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var ground_check: RayCast2D = $GroundCheck
@onready var attack_offset_x: float = absf(attack_area.position.x)
@onready var ground_offset_x: float = absf(ground_check.position.x)

var attacking: bool = false
var cooldown_left: float = 0.0
var hit_player: bool = false
var health: int = 1
var is_dead: bool = false
var is_hurt: bool = false

func _ready() -> void:
	health = maxi(max_health, 1)
	sprite.sprite_frames.set_animation_loop("attack1", false)
	sprite.sprite_frames.set_animation_loop("attack2", false)
	sprite.sprite_frames.set_animation_loop("hurt", false)
	sprite.sprite_frames.set_animation_loop("death", false)
	sprite.animation_finished.connect(_on_animation_finished)
	_face(1.0)
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	# Keep gravity, but stop AI and slash damage during hurt/death animations.
	if is_dead or is_hurt:
		velocity.x = 0.0
		move_and_slide()
		return

	# Complete a committed slash without turning to follow the player.
	if attacking:
		velocity.x = 0.0
		move_and_slide()
		_check_slash_hit()
		return

	var desired_speed: float = 0.0
	var player: PlayerController = GameManager.player
	if is_instance_valid(player) and not player.is_dead:
		var offset: Vector2 = player.global_position - global_position
		if offset.length() <= detection_range and _can_see(player):
			if absf(offset.x) > 1.0:
				_face(signf(offset.x))
			var in_reach: bool = absf(offset.x) <= attack_range and absf(offset.y) <= max_attack_height
			if in_reach:
				velocity.x = 0.0
				if cooldown_left <= 0.0 and is_on_floor():
					_start_attack()
			else:
				# The ray is repositioned by _face, so refresh it before checking.
				ground_check.force_raycast_update()
				if stop_at_edges and is_on_floor() and not ground_check.is_colliding():
					velocity.x = 0.0
				else:
					desired_speed = signf(offset.x) * chase_speed

	if attacking:
		velocity.x = 0.0
	else:
		velocity.x = move_toward(velocity.x, desired_speed, acceleration * delta)
		sprite.play("walk" if absf(velocity.x) > 1.0 else "idle")
	move_and_slide()

func _face(direction: float) -> void:
	# The unflipped demon sprites face right.
	sprite.flip_h = direction < 0.0
	attack_area.position.x = attack_offset_x * direction
	ground_check.position.x = ground_offset_x * direction

func _start_attack() -> void:
	if is_dead or is_hurt:
		return
	attacking = true
	hit_player = false
	velocity.x = 0.0
	sprite.stop()
	sprite.play(attack_animation)

func _check_slash_hit() -> void:
	if is_dead or is_hurt or hit_player or sprite.frame < active_start_frame or sprite.frame > active_end_frame:
		return
	for body in attack_area.get_overlapping_bodies():
		if body is PlayerController and not body.is_dead and _can_see(body):
			hit_player = true
			body.die()
			break

func _can_see(target: Node2D) -> bool:
	# Layer 1 is the solid world. This prevents attacks through walls.
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func take_damage(amount: int = 1) -> void:
	if is_dead or is_hurt or amount <= 0:
		return
	health = maxi(health - amount, 0)
	attacking = false
	velocity.x = 0.0
	if health == 0:
		_die()
	else:
		is_hurt = true
		sprite.stop()
		sprite.play("hurt")

func _die() -> void:
	is_dead = true
	is_hurt = false
	attacking = false
	hit_player = true
	remove_from_group("attackable")
	$Hurtbox.set_deferred("collision_layer", 0)
	$Hurtbox.set_deferred("monitorable", false)
	attack_area.set_deferred("monitoring", false)
	sprite.stop()
	sprite.play("death")

func _on_animation_finished() -> void:
	if sprite.animation == "death":
		queue_free()
	elif sprite.animation == "hurt":
		is_hurt = false
		cooldown_left = attack_cooldown
		sprite.play("idle")
	elif sprite.animation == attack_animation:
		attacking = false
		cooldown_left = attack_cooldown
		sprite.play("idle")

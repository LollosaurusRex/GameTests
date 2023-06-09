extends CharacterBody2D

@export var stopSpeed : float = 100
@export var groundFriction : float = 6

@export var walkSpeed : float = 100.0
@export var fastWalkSpeed : float = 150.0
@export var jogSpeed : float = 200.0
@export var runSpeed : float = 250.0

@export var groundAcceleration : float = 200
@export var groundDeceleration : float = 600

@export var maxTurnSpeed : float = 80
@export var maxAirTurnSpeed : float = 80

@export var maxAirAcceleration : float = 50
@export var maxAirDeceleration : float = 50

@export var jump_velocity : float = -150.0
@export var double_jump_velocity : float = -100.0

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collider : CollisionShape2D = $CollisionShape2D

@onready var weaponSlot : Node2D = $Weapon
@onready var actualWeapon = weaponSlot.get_child(0)
@onready var weaponRadius = actualWeapon.position.length()
var mousePos : Vector2

var facingRight : bool = true

@onready var feetMarker : Vector2 = $"HandsMarker2D".position

@export var tileMapsNode : Node
var groundTileMap : TileMap # = tileMapsNode.GroundTileMap
var backgroundTileMap : TileMap # = tileMapsNode.BackgroundTileMap

# z_index controls tile and player draw. Lower means more behind. Make sure to check the player is in front
# Must also consider collision_layer and mask

var canClimb : bool = false
@onready var wallClimbTimer : Timer = $"(Timer) WallClimbing"

var desiredVelocity : Vector2 = Vector2.ZERO
var deltaFrameTime : float = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jumped : bool = false
var animation_locked : bool = false

var inputDirection : Vector2 = Vector2.ZERO
var was_in_air : bool = false

enum states {IDLE, RUNNING, JUMPING, MANTLING}
var state : states = states.IDLE

var sprinting : bool = false

func _ready():
	if tileMapsNode:
		groundTileMap = tileMapsNode.get_node("GroundTileMap")
		backgroundTileMap = tileMapsNode.get_node("BackgroundTileMap")
	else:
		pass


func _process(delta):
	inputDirection = Input.get_vector("left", "right", "up", "down");
	
	desiredVelocity.x = sign(inputDirection.x) * 100
	if sprinting:
		desiredVelocity.x *= 2
		
	mousePos = get_local_mouse_position()


func _physics_process(delta):
	deltaFrameTime = delta
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		was_in_air = true
	else:
		has_double_jumped = false
		
		if was_in_air:
			land()
		
		was_in_air = false

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			jump()
		elif not has_double_jumped:
			# Then double jump in air
#			double_jump()
			pass
	
	if Input.is_action_pressed("up"):
		sprinting = true
	if Input.is_action_just_released("up"):
		sprinting = false
	
	# Retrieve the tilemap coordinate at the players center
	var tileMapCoord : Vector2i = groundTileMap.local_to_map(feetMarker + position)
	
	# layer, coord
	var tile : TileData = groundTileMap.get_cell_tile_data(1, tileMapCoord)
	
	canClimb = tile != null
#	print(canClimb)
	

	# Get the input inputDirection and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
#	inputDirection = Input.get_vector("left", "right", "up", "down");
	
		
	
#	if (animated_sprite.animation != "jump_end"):
#		# velocity.x = inputDirection.x * walkSpeed
#	friction()
#	accel(Vector2(inputDirection.x, 0), 320, 500)
	
#	velocity.x = move_toward(velocity.x, 0, walkSpeed)
	if Input.is_action_just_pressed("fire"):
		actualWeapon.attack()


	move()
	update_animation()
	update_facing_inputDirection()
	aimWeapon()
	

# Called once per physics frame, angle the weapon based on mouse look location
func aimWeapon() -> void:
	if (actualWeapon == null):
		return
	
	var pos : Vector2 = mousePos.normalized() * weaponRadius
	var angle = pos.angle()
	
	actualWeapon.position = pos
	actualWeapon.rotation = lerp_angle(actualWeapon.rotation, angle, 0.5)

#   Don't use these ones 
#	weapon.position.x = move_toward(weapon.position.x, pos.x, 1.5)
#	weapon.position.y = move_toward(weapon.position.y, pos.y, 1.5)
#	weapon.rotation = move_toward(weapon.rotation, angle, 0.5)
	

func move() -> void:
	var onGround : bool = is_on_floor()
	
	var acceleration = groundAcceleration if onGround else maxAirAcceleration
	var deceleration = groundDeceleration if onGround else maxAirDeceleration
	var turnSpeed    = maxTurnSpeed       if onGround else maxAirTurnSpeed
	
	if inputDirection.y == -1 && canClimb:
		climb()
		return
	
	
	var speedDelta : float = 0
	if (inputDirection.x != 0):
		if (sign(inputDirection.x) != sign(velocity.x)):
			speedDelta = turnSpeed * deltaFrameTime * (2 if sprinting else 1)
		else:
			speedDelta = acceleration * deltaFrameTime * (2 if sprinting else 1)
	else:
		speedDelta = deceleration * deltaFrameTime
		
	velocity.x = move_toward(velocity.x, desiredVelocity.x, speedDelta)
	move_and_slide()

func climb() -> void:
	if wallClimbTimer.is_stopped() and is_on_floor():
		wallClimbTimer.start()
		return
	
	
	
#	position.y -= 20
	velocity.x = 0
	velocity.y = -20
	
	pass


func update_animation() -> void:
	if not animation_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		else:
			# update to idle or run animation
			if inputDirection.x != 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")
	
	
func update_facing_inputDirection() -> void:
	if facingRight and inputDirection.x < 0:
		facingRight = false
#		scale.x *= -1
		animated_sprite.flip_h = true
	elif not facingRight and inputDirection.x > 0:
		facingRight = true
		animated_sprite.flip_h = false
#		scale.x *= -1
	
#	print(scale)
#	if inputDirection.x > 0:
##		animated_sprite.flip_h = false
#		scale.x = 1
#	elif inputDirection.x < 0:
#		if (scale.x == 1):
#			scale.x = -1 
##		animated_sprite.flip_h = true
##		scale.x = -1
		
		
func jump() -> void:
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animation_locked = true
	
	
func double_jump() -> void:
	velocity.y = double_jump_velocity
	animated_sprite.play("jump_double")
	animation_locked = true
	has_double_jumped = true
	
	
func land() -> void:
	animated_sprite.play("jump_end")
	animation_locked = true


func _on_animated_sprite_2d_animation_finished() -> void:
	if (["jump_end", "jump_start", "jump_double"].has(animated_sprite.animation)):
		animation_locked = false
		

func _on_tile_map_player_touching_background():
	pass # Replace with function body.

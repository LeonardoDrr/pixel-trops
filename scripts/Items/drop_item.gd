extends RigidBody2D

@export var item_name: String = "wood" # "wood", "copper_ore", etc.
@export var amount: int = 1
@export var magnet_radius: float = 60.0

var target_player: CharacterBody2D = null
var current_speed: float = 0.0
const MAX_SPEED: float = 300.0
const ACCELERATION: float = 1000.0

func _ready() -> void:
	# Small random impulse for "pop" effect
	apply_impulse(Vector2(randf_range(-50, 50), randf_range(-150, -50)))
	
	# Enable pickup after a short delay
	await get_tree().create_timer(0.5).timeout
	
	# Create Magnet Area dynamically if not present scene-side
	var magnet_area = Area2D.new()
	magnet_area.collision_layer = 0
	magnet_area.collision_mask = 2 # Detect Player (Layer 2)
	var shape = CircleShape2D.new()
	shape.radius = magnet_radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	magnet_area.add_child(collision)
	add_child(magnet_area)
	
	magnet_area.body_entered.connect(_on_magnet_area_entered)
	
	# Ensure existing pickup area works (Scene has "Area2D" child usually)
	if has_node("Area2D"):
		$Area2D.body_entered.connect(_on_pickup_area_entered)

func _physics_process(delta: float) -> void:
	if target_player:
		# Disable physics simulation once magnetized
		if freeze_mode != FREEZE_MODE_KINEMATIC:
			freeze = true
			freeze_mode = FREEZE_MODE_KINEMATIC
			
		var direction = (target_player.global_position - global_position).normalized()
		current_speed = move_toward(current_speed, MAX_SPEED, ACCELERATION * delta)
		
		# Move manually
		global_position += direction * current_speed * delta
		
		# Proximity safety net: if we are very close, pick up even if Area2D missed it
		if global_position.distance_to(target_player.global_position) < 10.0:
			_pickup(target_player)

func _on_magnet_area_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target_player = body
		current_speed = 50.0 

func _on_pickup_area_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_pickup(body)

var is_collecting: bool = false

func _pickup(player: Node) -> void:
	if is_collecting: return
	is_collecting = true
	
	if player.has_method("add_item"):
		player.add_item(item_name, amount)
		visible = false 
		set_physics_process(false)
		collision_layer = 0
		collision_mask = 0
		call_deferred("queue_free") 

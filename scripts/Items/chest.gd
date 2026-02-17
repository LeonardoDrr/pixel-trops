extends StaticBody2D

@onready var inventory_ui: Control = $CanvasLayer/InventoryUI
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D

var is_open: bool = false
var player_in_range: CharacterBody2D = null

func _ready() -> void:
	# Interaction area setup
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Connect input event for click detection
	input_pickable = true 
	# Note: StaticBody2D input_event works if pickable is true
	# But we also have an Area2D for range.
	# We can use the Area2D for clicks too if we want, or the body.
	# Let's use a specific ClickArea or the InteractionArea if it's large enough.
	# Actually, usually you click the sprite. So let's add a ClickArea fitting the sprite.

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body is CharacterBody2D:
		player_in_range = body
		print("Player entered chest range")

func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		close_chest()
		print("Player exited chest range")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if player_in_range:
			# Check if mouse is over the chest sprite
			var mouse_pos = get_global_mouse_position()
			var sprite_rect = Rect2(sprite.global_position - (sprite.get_rect().size * sprite.scale / 2), sprite.get_rect().size * sprite.scale)
			
			if sprite_rect.has_point(mouse_pos):
				print("Right click detected on chest!")
				toggle_chest()

func toggle_chest() -> void:
	if is_open:
		close_chest()
	else:
		open_chest()

func open_chest() -> void:
	if not player_in_range: return
	is_open = true
	inventory_ui.open(player_in_range)
	# Optional: Change sprite to open frame

func close_chest() -> void:
	is_open = false
	inventory_ui.close()
	# Optional: Change sprite to closed frame

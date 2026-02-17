extends Control

@onready var grid_container: GridContainer = $Background/GridContainer
@onready var background: TextureRect = $Background
@onready var close_button: TextureButton = $Background/CloseButton

const SlotScene = preload("res://scenes/UI/InventorySlot.tscn")
const WOOD_ICON = preload("res://assets/Items/Materiales/sin procesar/tronco de roble.png")
const COPPER_ICON = preload("res://assets/Items/Materiales/sin procesar/polvo de cobre.png")

func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func update_inventory(player: CharacterBody2D) -> void:
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	# Add items
	_add_item_slot("Wood", WOOD_ICON, player.wood)
	_add_item_slot("Copper Ore", COPPER_ICON, player.copper_ore)

func _add_item_slot(item_name: String, icon: Texture2D, quantity: int) -> void:
	if quantity <= 0: return
	
	var slot = SlotScene.instantiate()
	grid_container.add_child(slot)
	slot.setup(icon, item_name, quantity)

func _input(event: InputEvent) -> void:
	if not visible: return
	
	# Close on ESC
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	
	# Close on left click outside inventory
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var bg_rect = Rect2(background.global_position, background.size)
		
		if not bg_rect.has_point(mouse_pos):
			close()
			get_viewport().set_input_as_handled()

func _on_close_button_pressed() -> void:
	close()

func open(player: CharacterBody2D) -> void:
	update_inventory(player)
	visible = true

func close() -> void:
	visible = false

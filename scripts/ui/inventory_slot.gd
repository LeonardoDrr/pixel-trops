extends Control

@onready var slot_bg: TextureRect = $SlotBackground
@onready var item_icon: TextureRect = $ItemIcon
@onready var item_name_label: Label = $ItemName
@onready var quantity_label: Label = $Quantity

const SLOT_NORMAL = preload("res://assets/hub/casilla.png")
const SLOT_SELECTED = preload("res://assets/hub/casilla seleccionada.png")

var is_selected: bool = false

func _ready() -> void:
	item_icon.visible = false
	item_name_label.visible = false
	quantity_label.visible = false

func setup(icon: Texture2D, item_name: String, quantity: int) -> void:
	if icon:
		item_icon.texture = icon
		item_icon.visible = true
	
	if item_name:
		item_name_label.text = item_name
		item_name_label.visible = true
	
	if quantity > 0:
		quantity_label.text = "x" + str(quantity)
		quantity_label.visible = true

func clear() -> void:
	item_icon.visible = false
	item_name_label.visible = false
	quantity_label.visible = false

func set_selected(selected: bool) -> void:
	is_selected = selected
	slot_bg.texture = SLOT_SELECTED if selected else SLOT_NORMAL

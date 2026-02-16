extends CanvasLayer

@onready var mana_bar_container: Control = $Control/ManaBarContainer
@onready var mana_bar_bg: ColorRect = $Control/ManaBarContainer/Background
@onready var mana_bar_fill: ColorRect = $Control/ManaBarContainer/Fill
@onready var mana_bar_shine: ColorRect = $Control/ManaBarContainer/Shine
@onready var mana_label: Label = $Control/ManaBarContainer/Label
@onready var hp_label: Label = $Control/HPLabel
@onready var arrow_label: Label = $Control/ArrowCounter/Label
@onready var hotbar_container: HBoxContainer = $Control/Hotbar
@onready var hearts_container: HBoxContainer = $Control/HeartsContainer

const SlotScene = preload("res://scenes/UI/HotbarSlot.tscn")
const HEART_FULL = preload("res://assets/hub/ui_heart_full.png")
const HEART_HALF = preload("res://assets/hub/ui_heart_mitad.png")
const HEART_EMPTY = preload("res://assets/hub/ui_heart_empty.png")

var slots: Array = []
var heart_icons: Array[TextureRect] = []
var max_hearts: int = 5
var current_hp: int = 100
var max_hp: int = 100
var hp_per_heart: int = 20  # Cada corazón = 20 HP

var mana_tween: Tween
var shake_tween: Tween

func _ready() -> void:
	_initialize_hearts()

func _initialize_hearts() -> void:
	# Limpiar corazones existentes
	for child in hearts_container.get_children():
		child.queue_free()
	heart_icons.clear()
	
	# Crear corazones basados en max_hp
	max_hearts = ceili(float(max_hp) / hp_per_heart)
	
	for i in range(max_hearts):
		var heart = TextureRect.new()
		heart.texture = HEART_FULL
		heart.custom_minimum_size = Vector2(20, 20)
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(heart)
		heart_icons.append(heart)

func initialize_hotbar(weapons_data: Array) -> void:
	# Clear existing
	for child in hotbar_container.get_children():
		child.queue_free()
	slots.clear()
	
	var key_num = 1
	for data in weapons_data:
		var slot = SlotScene.instantiate()
		hotbar_container.add_child(slot)
		slot.setup(data["type"], data["icon"], key_num)
		slots.append(slot)
		key_num += 1

func select_slot(index: int) -> void:
	for i in range(slots.size()):
		slots[i].set_selected(i == index)

func update_health(current: int, max_hp_val: int) -> void:
	current_hp = current
	max_hp = max_hp_val
	
	# Actualizar label numérico
	hp_label.text = str(current) + " / " + str(max_hp)
	
	# Recalcular hearts si max_hp cambió
	var needed_hearts = ceili(float(max_hp) / hp_per_heart)
	if needed_hearts != max_hearts:
		max_hearts = needed_hearts
		_initialize_hearts()
	
	# Actualizar visualización de corazones
	_update_hearts_display()
	
	# Efecto de sacudida si recibió daño
	if current < max_hp:
		_shake_hearts()

func _update_hearts_display() -> void:
	var hearts_to_fill = float(current_hp) / hp_per_heart
	
	for i in range(heart_icons.size()):
		var heart = heart_icons[i]
		var heart_value = hearts_to_fill - i
		
		if heart_value >= 1.0:
			# Corazón lleno
			heart.texture = HEART_FULL
		elif heart_value >= 0.5:
			# Medio corazón
			heart.texture = HEART_HALF
		else:
			# Corazón vacío
			heart.texture = HEART_EMPTY

func _shake_hearts() -> void:
	if shake_tween:
		shake_tween.kill()
	
	shake_tween = create_tween()
	shake_tween.tween_property(hearts_container, "position:x", hearts_container.position.x + 5, 0.05)
	shake_tween.tween_property(hearts_container, "position:x", hearts_container.position.x - 5, 0.05)
	shake_tween.tween_property(hearts_container, "position:x", hearts_container.position.x + 3, 0.05)
	shake_tween.tween_property(hearts_container, "position:x", hearts_container.position.x, 0.05)

func update_mana(current: int, max_mana: int) -> void:
	var ratio = float(current) / max_mana
	mana_label.text = str(current) + " / " + str(max_mana)
	
	# Animar el cambio de tamaño
	if mana_tween:
		mana_tween.kill()
	
	mana_tween = create_tween()
	mana_tween.set_ease(Tween.EASE_OUT)
	mana_tween.set_trans(Tween.TRANS_CUBIC)
	mana_tween.tween_property(mana_bar_fill, "size:x", 200.0 * ratio, 0.3)

func update_arrows(count: int) -> void:
	arrow_label.text = str(count)

func trigger_weapon_cooldown(slot_index: int, duration: float) -> void:
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].start_cooldown(duration)

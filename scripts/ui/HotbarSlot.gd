extends TextureRect

@onready var icon: TextureRect = $Icon
@onready var highlight: ColorRect = $Highlight
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var cooldown_label: Label = $CooldownOverlay/CooldownLabel
@onready var key_number: Label = $KeyNumber

var is_selected: bool = false
var is_on_cooldown: bool = false
var pulse_tween: Tween

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(weapon_type: String, weapon_icon: Texture2D, key_num: int = 1) -> void:
	# Set Background based on type
	match weapon_type:
		"melee":
			texture = preload("res://assets/Items/box melee.png")
		"range":
			texture = preload("res://assets/Items/box range.png")
		"mage":
			texture = preload("res://assets/Items/box mage.png")
		_:
			texture = preload("res://assets/Items/box melee.png") # Default
	
	# Set Icon
	if weapon_icon:
		icon.texture = weapon_icon
	
	# Set Key Number
	key_number.text = str(key_num)

func set_selected(selected: bool) -> void:
	is_selected = selected
	highlight.visible = selected
	
	# Cancel previous pulse animation
	if pulse_tween:
		pulse_tween.kill()
	
	if selected:
		# Start pulse animation
		_start_pulse_animation()
	else:
		# Reset scale
		scale = Vector2.ONE

func _start_pulse_animation() -> void:
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.5).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)

func start_cooldown(duration: float) -> void:
	if is_on_cooldown:
		return
	
	is_on_cooldown = true
	cooldown_overlay.visible = true
	
	var time_left = duration
	while time_left > 0:
		cooldown_label.text = "%.1f" % time_left
		await get_tree().create_timer(0.1).timeout
		time_left -= 0.1
	
	cooldown_overlay.visible = false
	is_on_cooldown = false

func _on_mouse_entered() -> void:
	if not is_selected:
		# Subtle scale up on hover
		create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	if not is_selected:
		# Scale back down
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

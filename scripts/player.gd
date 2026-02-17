extends CharacterBody2D

const WALK_SPEED = 150.0
const RUN_SPEED = 280.0
const JUMP_VELOCITY = -220.0
const MAX_HP = 100
const CRIT_CHANCE = 0.15  # 15% chance for critical hit (3 dmg)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var parallax_layer: ParallaxLayer = get_parent().get_node_or_null("ParallaxBackground/ParallaxLayer")
@onready var bg_sprite: Sprite2D = get_parent().get_node_or_null("ParallaxBackground/ParallaxLayer/Sprite2D")

var bg_textures = [
	preload("res://assets/fondo 1.jpg"),
	preload("res://assets/fondo 2.jpg")
]
var bg_timer = 0.0
var bg_frame = 0

# @onready var attack_area: Area2D = $"dañar" # Deprecated

var is_attacking: bool = false
var is_running: bool = false
var hp: int = MAX_HP
var is_dead: bool = false
var has_dealt_damage: bool = false # Still used internally? Maybe not, but keep safe
var spawn_position: Vector2
var can_knockback: bool = true

# --- Resources ---
var mana: float = 100.0
var max_mana: float = 100.0
var mana_regen_rate: float = 0.5 # Mana per second (Slow regen)

var arrows: int = 30

# --- Inventory ---
var wood: int = 0
var copper_ore: int = 0

# --- Auto-Harvesting (AFK) ---
var is_gathering: bool = false
var gathering_timer: float = 0.0
var nearby_resources: Array = []
var previous_weapon_index: int = -1
const AFK_TIME_THRESHOLD: float = 3.0


# --- UI ---
const HUD_SCENE = preload("res://scenes/UI/HUD.tscn")
var hud: CanvasLayer

func _input(event: InputEvent) -> void:
	# Attack input moved to _physics_process for auto-attack

	# --- Weapon Switching (Scroll Wheel) ---
	if event.is_action_pressed("weapon_next"):
		_cycle_weapon(1)
	elif event.is_action_pressed("weapon_prev"):
		_cycle_weapon(-1)
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_switch_to_weapon(0)
		elif event.keycode == KEY_2:
			_switch_to_weapon(1)
		elif event.keycode == KEY_3:
			_switch_to_weapon(2)

var weapon_scenes = [
	preload("res://scenes/Weapons/Swords/Sword_Wood.tscn"),
	preload("res://scenes/Weapons/Bows/Bow_Wood.tscn"),
	preload("res://scenes/Weapons/Staffs/Staff_Fire.tscn")
]

var tool_scenes = [
	preload("res://scenes/Weapons/Tools/Axe_Copper.tscn"),
	preload("res://scenes/Weapons/Tools/Pickaxe_Copper.tscn")
]
var current_weapon_index: int = 0

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	anim.animation_finished.connect(_on_animation_finished)
	
	# Instantiate HUD
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	
	# Initialize Hotbar
	var weapons_data = []
	for scene in weapon_scenes:
		var w = scene.instantiate()
		weapons_data.append({
			"type": w.get_weapon_type(),
			"icon": w.get_idle_texture()
		})
		w.queue_free()
	
	hud.initialize_hotbar(weapons_data)
	
	_update_ui()
	
	# Ensure weapon renders in front of player
	if has_node("WeaponHolder"):
		$WeaponHolder.z_index = 1
	
	# Instantiate Default Weapon
	_switch_to_weapon(0)

func _cycle_weapon(direction: int) -> void:
	current_weapon_index += direction
	
	if current_weapon_index >= weapon_scenes.size():
		current_weapon_index = 0
	elif current_weapon_index < 0:
		current_weapon_index = weapon_scenes.size() - 1
		
	_switch_to_weapon(current_weapon_index) # Use common function

func _switch_to_weapon(index: int) -> void:
	if index >= 0 and index < weapon_scenes.size():
		current_weapon_index = index
		equip_weapon(weapon_scenes[index])
		if hud:
			hud.select_slot(index)

func equip_weapon(weapon_packed: PackedScene) -> void:
	# Eliminar arma actual si existe
	for child in $WeaponHolder.get_children():
		child.queue_free()
	
	# Instanciar nueva
	var new_weapon = weapon_packed.instantiate()
	$WeaponHolder.call_deferred("add_child", new_weapon)



func _process(delta: float) -> void:
	if is_dead: return
	
	# Passive Mana Regen
	if mana < max_mana:
		mana += mana_regen_rate * delta
		mana = min(mana, max_mana)
	if mana < max_mana:
		mana += mana_regen_rate * delta
		mana = min(mana, max_mana)
		hud.update_mana(int(mana), int(max_mana))
		
	# --- Auto-Harvest Logic ---
	if velocity == Vector2.ZERO and not is_gathering and not is_dead:
		# Check if near resources
		_update_nearby_resources()
		if nearby_resources.size() > 0:
			gathering_timer += delta
			if gathering_timer >= AFK_TIME_THRESHOLD:
				_start_gathering_mode()
		else:
			gathering_timer = 0.0
	elif velocity != Vector2.ZERO or Input.is_action_just_pressed("attack") or is_dead:
		# Cancel gathering on move or manual attack
		if is_gathering:
			_stop_gathering_mode()
		gathering_timer = 0.0
		
	if is_gathering:
		# Auto-attack mechanism
		if has_node("WeaponHolder") and $WeaponHolder.get_child_count() > 0:
			var weapon = $WeaponHolder.get_child(0)
			# Look at resource
			if nearby_resources.size() > 0:
				var target_res = nearby_resources[0]
				if is_instance_valid(target_res):
					var direction = (target_res.global_position - global_position).normalized()
					# Aim at it
					# (Optional: flip sprite)
					if direction.x < 0: anim.flip_h = true
					else: anim.flip_h = false
					
					# Attack
					if weapon.has_method("attack") and weapon.can_attack:
						weapon.attack()
				else:
					# Resource destroyed
					nearby_resources.erase(target_res)
					if nearby_resources.size() == 0:
						_stop_gathering_mode()


func _update_ui() -> void:
	if hud:
		hud.update_health(hp, MAX_HP)
		hud.update_mana(int(mana), int(max_mana))
		hud.update_arrows(arrows)

func change_mana(amount: float) -> bool:
	if mana + amount >= 0:
		mana += amount
		mana = clamp(mana, 0, max_mana)
		hud.update_mana(int(mana), int(max_mana))
		return true
	return false

func change_arrows(amount: int) -> bool:
	if arrows + amount >= 0:
		arrows += amount
		hud.update_arrows(arrows)
		return true
	return false

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Animación del fondo
	if bg_sprite:
		bg_timer += delta
		if bg_timer >= 0.5: # Cambia cada 0.5 segundos
			bg_timer = 0.0
			bg_frame = (bg_frame + 1) % bg_textures.size()
			bg_sprite.texture = bg_textures[bg_frame]

	# --- Gravity ---

	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- Jump ---
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# --- Run detection (Shift held) ---
	is_running = Input.is_action_pressed("run")

	# --- Camera Zoom ---
	var zoom_speed = 2.0 * delta
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_PLUS): # Zoom In
		camera.zoom += Vector2(zoom_speed, zoom_speed)
	elif Input.is_key_pressed(KEY_MINUS): # Zoom Out
		camera.zoom -= Vector2(zoom_speed, zoom_speed)
	
	# Clamp zoom (Limits: 1.0 to 5.0)
	camera.zoom = camera.zoom.clamp(Vector2(1.0, 1.0), Vector2(5.0, 5.0))

	# --- Mouse Aiming & Face Direction (Terraria Style) ---
	var mouse_pos = get_global_mouse_position()
	
	# Flip sprite based on mouse position
	anim.flip_h = mouse_pos.x < global_position.x

	# Rotate and Position Weapon Holder
	if has_node("WeaponHolder") and $WeaponHolder.get_child_count() > 0:
		var weapon_holder = $WeaponHolder
		var weapon = weapon_holder.get_child(0)
		var rotate_enabled = true
		
		# --- Flip Position logic (Keep weapon in 'front' hand) ---
		# If aiming left, move holder to left side. If right, move to right.
		if mouse_pos.x < global_position.x:
			weapon_holder.position.x = -abs(weapon_holder.position.x)
		else:
			weapon_holder.position.x = abs(weapon_holder.position.x)
		
		if "rotate_to_mouse" in weapon:
			rotate_enabled = weapon.rotate_to_mouse
			
		if rotate_enabled:
			# Free rotation (Bows, Staffs)
			weapon_holder.look_at(mouse_pos)
			weapon_holder.scale.x = 1 # Force reset X scale (fix transition from Sword)
			if mouse_pos.x < global_position.x:
				weapon_holder.scale.y = -1
			else:
				weapon_holder.scale.y = 1
		else:
			# Static rotation (Swords) - Flip only
			weapon_holder.rotation = 0
			weapon_holder.scale.y = 1
			
			if mouse_pos.x < global_position.x:
				weapon_holder.scale.x = -1
			else:
				weapon_holder.scale.x = 1

	# --- Horizontal movement ---
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		var speed = RUN_SPEED if is_running else WALK_SPEED
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

	move_and_slide()

	if parallax_layer:
		parallax_layer.motion_offset.x = global_position.x * -0.001

	# --- Keep health bar following the character (in global coords) ---
	# HUD is a CanvasLayer, so no manual positioning needed

	# --- Auto-Attack (Hold button) ---
	if Input.is_action_pressed("attack"):
		if has_node("WeaponHolder") and $WeaponHolder.get_child_count() > 0:
			var weapon = $WeaponHolder.get_child(0)
			if weapon.has_method("attack"):
				weapon.attack()

	# --- Sprite flip ---
	if direction != 0:
		anim.flip_h = direction < 0

	# --- Animation state machine ---
	if not is_on_floor():
		_play_if_not("Jump")
	elif direction != 0:
		if is_running:
			_play_if_not("Run ")
		else:
			_play_if_not("Walk")
	else:
		_play_if_not("Idle")
	




func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dead:
		return
	hp -= amount
	hp = max(hp, 0)
	if hud:
		hud.update_health(hp, MAX_HP)
	_flash_damage()
	_show_damage_number(amount, is_crit)
	if hp <= 0:
		_die()

func _flash_damage() -> void:
	anim.modulate = Color(1.0, 0.3, 0.3, 1.0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.25)

func _show_damage_number(amount: int, is_crit: bool) -> void:
	var container = Node2D.new()
	container.top_level = true
	container.global_position = global_position
	add_child(container)

	var label = Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 12 if is_crit else 8)
	if is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))  # amarillo
	else:
		label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-4, -28)
	container.add_child(label)

	# Animar: sube y se desvanece
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 15, 0.6)
	tw.tween_property(label, "modulate:a", 0.0, 0.6)
	tw.set_parallel(false)
	tw.tween_callback(container.queue_free)

func trigger_knockback_cooldown() -> void:
	can_knockback = false
	get_tree().create_timer(3.0).timeout.connect(func(): can_knockback = true)

func _die() -> void:
	is_dead = true
	visible = false
	if hud: hud.visible = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	# Respawn after 5 seconds
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_respawn)

func _respawn() -> void:
	hp = MAX_HP
	mana = max_mana
	global_position = spawn_position
	is_dead = false
	is_attacking = false
	visible = true
	if hud: 
		hud.visible = true
		_update_ui()
	set_physics_process(true)
	anim.play("Idle")

func _play_if_not(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

func add_item(item_name: String, amount: int) -> void:
	match item_name:
		"wood":
			wood += amount
			print("Wood collected: ", wood)
		"copper_ore":
			copper_ore += amount
			print("Copper Ore collected: ", copper_ore)
	# TODO: Update UI if/when inventory UI exists

# --- Harvesting Helpers ---

func _update_nearby_resources() -> void:
	# Scan for resources in small radius
	var space_state = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = 40.0 # Small range
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 9 # Check Layer 1 (World) and Layer 4 (Interactable)
	
	var results = space_state.intersect_shape(query)
	nearby_resources.clear()
	
	for res in results:
		var collider = res.collider
		if collider.has_method("get_tool_type"): # Identify as resource
			nearby_resources.append(collider)

func _start_gathering_mode() -> void:
	if nearby_resources.size() == 0: return
	
	# Identify needed tool
	var target_resource = nearby_resources[0]
	var required_tool = target_resource.get_tool_type()
	
	# Find tool in dedicated tool list
	var found_tool_scene = null
	
	for scene in tool_scenes:
		# Use metadata or instantiate to check type
		# Optimization: Check scene path string or similar if consistent, but instantiation is safest for now
		var t_instance = scene.instantiate()
		var t_type = t_instance.get("tool_type")
		t_instance.queue_free()
		
		if t_type == required_tool:
			found_tool_scene = scene
			break
	
	if found_tool_scene:
		previous_weapon_index = current_weapon_index
		is_gathering = true
		equip_weapon(found_tool_scene)
		# Clean selection in HUD if desired (pass -1)
		if hud: hud.select_slot(-1) 
		print("Auto-Harvesting Started: Switched to ", required_tool)
	else:
		print("No tool found for resource: ", required_tool)
		gathering_timer = 0.0 # Reset timer to avoid spamming check

func _stop_gathering_mode() -> void:
	is_gathering = false
	gathering_timer = 0.0
	if previous_weapon_index != -1:
		_switch_to_weapon(previous_weapon_index)
		previous_weapon_index = -1
		print("Auto-Harvesting Stopped: Weapon restored")

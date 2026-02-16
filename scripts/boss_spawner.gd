extends Node2D

## Boss Spawner - Spawns ONE boss at a time with cooldown
## WORKAROUND: Preload scenes directly to avoid Array[PackedScene] issues

# Preload the boss scenes directly
const BOSS_EVIL_WIZARD = preload("res://scenes/boss/Boss_EvilWizard.tscn")
const BOSS_HUNTRESS = preload("res://scenes/boss/Boss_Huntress.tscn")
const BOSS_KNIGHT = preload("res://scenes/boss/Boss_Knight.tscn")

@export var spawn_interval: float = 20.0
@export var max_bosses: int = 1  # Only 1 boss alive at a time

var timer: Timer
var current_boss: Node = null
var boss_scenes_list: Array[PackedScene] = []

func _ready() -> void:
	# WORKAROUND: Build the array manually using preloaded constants
	boss_scenes_list = [BOSS_EVIL_WIZARD, BOSS_HUNTRESS, BOSS_KNIGHT]
	
	# Create and start the timer
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_try_spawn_boss)
	add_child(timer)
	
	# Spawn first boss after short delay
	await get_tree().create_timer(2.0).timeout
	_try_spawn_boss()

func _try_spawn_boss() -> void:
	# Check if boss is still alive
	if current_boss and is_instance_valid(current_boss):
		return  # Boss still alive, don't spawn
	
	# Check for any bosses in scene (in case player didn't kill it)
	var bosses = get_tree().get_nodes_in_group("bosses")
	if bosses.size() >= max_bosses:
		return
	
	# Select random boss from preloaded list
	if boss_scenes_list.is_empty():
		return
	
	var selected_scene = boss_scenes_list.pick_random()
	var boss = selected_scene.instantiate()
	boss.global_position = global_position
	
	# Track this boss
	current_boss = boss
	
	# Add to scene
	get_parent().call_deferred("add_child", boss)

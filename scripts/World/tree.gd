extends StaticBody2D

@export var health: int = 3
@export var drop_scene: PackedScene
@export var min_drops: int = 2
@export var max_drops: int = 4
@export var tool_required: String = "axe" # "axe", "pickaxe"

@onready var sprite: Sprite2D = $Sprite2D

func take_damage(amount: int, is_crit: bool = false) -> void:
	# Visual flash
	if sprite:
		sprite.modulate = Color(1, 0, 0)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	health -= 1 # Trees take 1 hit per swing usually, regardless of damage
	
	if health <= 0:
		die()

func die() -> void:
	if drop_scene:
		var num_drops = randi_range(min_drops, max_drops)
		for i in range(num_drops):
			var drop = drop_scene.instantiate()
			drop.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			get_parent().call_deferred("add_child", drop)
	
	queue_free()

func get_tool_type() -> String:
	return tool_required

extends StaticBody2D

@export var health: int = 4
@export var drop_scene: PackedScene
@export var min_drops: int = 1
@export var max_drops: int = 3
@export var tool_required: String = "pickaxe"

@onready var sprite: Sprite2D = $Sprite2D

func take_damage(amount: int, is_crit: bool = false) -> void:
	if sprite:
		sprite.modulate = Color(1, 0.5, 0.5)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	health -= 1
	if health <= 0:
		die()

func die() -> void:
	if drop_scene:
		var num_drops = randi_range(min_drops, max_drops)
		for i in range(num_drops):
			var drop = drop_scene.instantiate()
			drop.global_position = global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
			get_parent().call_deferred("add_child", drop)
	
	queue_free()

func get_tool_type() -> String:
	return tool_required

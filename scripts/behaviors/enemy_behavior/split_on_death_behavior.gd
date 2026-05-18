# ==============================================================================
#   split_on_death_behavior.gd
#   功能：死亡分裂行为。敌人死亡时分裂为 2 个较小的同类。
# ==============================================================================
class_name SplitOnDeathBehavior extends EnemyBehavior

@export var split_scene: PackedScene
@export var split_count: int = 2
@export var split_scale: float = 0.6

var _has_split: bool = false

func _on_setup() -> void:
	if enemy:
		enemy.health_component.unit_died.connect(_on_host_died)

func _on_update(_delta: float) -> void:
	pass

func _on_host_died() -> void:
	if _has_split or split_scene == null:
		return
	_has_split = true

	for i in split_count:
		var child: Enemy = split_scene.instantiate()
		var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
		child.global_position = enemy.global_position + offset
		child.scale = Vector2(split_scale, split_scale)
		enemy.get_parent().add_child(child)

	if Global.DEBUG_MODE:
		print("[SplitOnDeathBehavior] 分裂为 ", split_count, " 个")

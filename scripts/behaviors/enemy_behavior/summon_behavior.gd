# ==============================================================================
#   summon_behavior.gd
#   功能：召唤行为。定期召唤小怪助战。
# ==============================================================================
class_name SummonBehavior extends TriggerableBehavior

@export var summon_scene: PackedScene
@export var max_summons: int = 3

var _active_summons: int = 0

func _execute_behavior() -> void:
	if summon_scene == null or enemy == null:
		return
	if _active_summons >= max_summons:
		return

	var minion: Enemy = summon_scene.instantiate()
	var offset := Vector2(randf_range(-50, 50), randf_range(-50, 50))
	minion.global_position = enemy.global_position + offset
	enemy.get_parent().add_child(minion)
	_active_summons += 1
	minion.tree_exited.connect(func() -> void: _active_summons -= 1)

	if Global.DEBUG_MODE:
		print("[SummonBehavior] 召唤小怪")

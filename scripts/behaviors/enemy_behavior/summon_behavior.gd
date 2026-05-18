# ==============================================================================
#   summon_behavior.gd
#   功能：召唤行为。定期召唤小怪助战。
# ==============================================================================
class_name SummonBehavior extends EnemyBehavior

@export var summon_scene: PackedScene
@export var summon_interval: float = 10.0
@export var max_summons: int = 3

var _summon_timer: float = 0.0
var _active_summons: int = 0

func _on_setup() -> void:
	_summon_timer = summon_interval

func _on_update(delta: float) -> void:
	if summon_scene == null:
		return

	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = summon_interval
		if _active_summons < max_summons:
			_summon()

func _summon() -> void:
	if enemy == null:
		return
	var minion: Enemy = summon_scene.instantiate()
	var offset := Vector2(randf_range(-50, 50), randf_range(-50, 50))
	minion.global_position = enemy.global_position + offset
	enemy.get_parent().add_child(minion)
	_active_summons += 1
	minion.tree_exited.connect(func() -> void: _active_summons -= 1)

	if Global.DEBUG_MODE:
		print("[SummonBehavior] 召唤小怪")

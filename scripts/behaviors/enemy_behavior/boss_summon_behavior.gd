# ==============================================================================
#   boss_summon_behavior.gd
#   功能：Boss召唤行为。召唤小兵协助战斗。
# ==============================================================================
class_name BossSummonBehavior extends TriggerableBehavior

## 召唤的敌人场景
@export var summon_scene: PackedScene

## 每次召唤数量
@export var summon_count: int = 3

## 召唤位置偏移范围
@export var spawn_radius: float = 150.0

## 最大同时存活数量
@export var max_alive_summons: int = 6

## 已召唤的敌人列表
var _summoned_enemies: Array[Node2D] = []

# ========================== 行为执行 ==========================
func _execute_behavior() -> void:
	if summon_scene == null or enemy == null:
		return

	_cleanup_dead_summons()
	if _summoned_enemies.size() >= max_alive_summons:
		return

	_summon_enemies()

func _summon_enemies() -> void:
	for i in summon_count:
		var minion: Node2D = summon_scene.instantiate()
		if minion == null:
			continue

		# 计算召唤位置（Boss周围随机位置）
		var angle: float = randf_range(0, TAU)
		var distance: float = randf_range(50.0, spawn_radius)
		var spawn_pos: Vector2 = enemy.global_position + Vector2.from_angle(angle) * distance

		enemy.get_parent().add_child(minion)
		minion.global_position = spawn_pos
		_summoned_enemies.append(minion)

		_play_summon_effect(spawn_pos)

	if Global.DEBUG_MODE:
		print("[BossSummonBehavior] 召唤了 ", summon_count, " 个敌人")

func _play_summon_effect(_pos: Vector2) -> void:
	# TODO: 播放召唤特效
	pass

func _cleanup_dead_summons() -> void:
	_summoned_enemies = _summoned_enemies.filter(func(e): return is_instance_valid(e))

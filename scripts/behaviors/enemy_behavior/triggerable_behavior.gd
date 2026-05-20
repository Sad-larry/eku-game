# ==============================================================================
#   triggerable_behavior.gd
#   功能：可触发行为中间层。在 EnemyBehavior 基础上增加触发器系统。
#        通过 BehaviorTrigger 数组控制行为何时被激活，实现条件驱动的行为执行。
#   设计：继承 EnemyBehavior，子类只需重写 _execute_behavior() 实现具体逻辑。
# ==============================================================================
class_name TriggerableBehavior
extends EnemyBehavior

# ========================== 导出变量 ==========================
## 触发器列表（满足任一触发器即执行行为）
@export var triggers: Array[Resource] = []

## 行为执行后的冷却时间（秒），0 表示无冷却
@export var behavior_cooldown: float = 0.0

## 最大执行次数，-1 表示无限
@export var max_executions: int = -1

# ========================== 运行时状态 ==========================
var _cooldown_timer: float = 0.0
var _execution_count: int = 0

# ========================== 生命周期 ==========================
func _on_update(delta: float) -> void:
	# 检查执行次数限制
	if max_executions >= 0 and _execution_count >= max_executions:
		return

	# 更新冷却
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	if _cooldown_timer > 0.0:
		return

	# 构建上下文并检查触发器
	var context := _build_context(delta)
	for trigger in triggers:
		if trigger != null and trigger.is_triggered(context):
			_execute_behavior()
			_execution_count += 1
			if behavior_cooldown > 0.0:
				_cooldown_timer = behavior_cooldown
			break

# ========================== 上下文构建 ==========================
## 功能：构建运行时上下文字典，供触发器判断条件
func _build_context(delta: float) -> Dictionary:
	var ctx := {"delta": delta}
	if enemy:
		var max_hp: int = enemy.health_component.max_health
		if max_hp > 0:
			ctx["health_pct"] = float(enemy.health_component.current_health) / max_hp
		else:
			ctx["health_pct"] = 1.0
		ctx["player_detected"] = enemy.player_detected
		var target = enemy.get_target()
		if target:
			ctx["player_distance"] = enemy.global_position.distance_to(target.global_position)
		else:
			ctx["player_distance"] = INF
	# Boss 特有上下文
	if enemy is EnemyBoss:
		ctx["boss_phase"] = enemy.get_current_phase()
	return ctx

# ========================== 可重写钩子 ==========================
## 功能：执行行为逻辑（子类必须重写）
func _execute_behavior() -> void:
	pass

## 功能：重置触发器和执行计数（用于阶段切换等场景）
func reset_triggers() -> void:
	_execution_count = 0
	_cooldown_timer = 0.0
	for trigger in triggers:
		if trigger != null and trigger is BehaviorTrigger:
			trigger.reset()

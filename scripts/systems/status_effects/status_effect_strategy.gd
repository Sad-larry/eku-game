# ==============================================================================
#   status_effect_strategy.gd
#   功能：状态效果执行策略基类。定义效果施加、移除、Tick 时的逻辑行为。
#        具体策略（DOT、减速、眩晕等）继承此类并覆写钩子方法。
# ==============================================================================
class_name StatusEffectStrategy extends RefCounted

# ========================== 虚方法钩子 ==========================
## 功能：效果首次施加时调用
## 参数：instance - 运行时实例，owner - 被施加效果的实体节点
func on_apply(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

## 功能：效果按 tick_interval 周期性调用
## 参数：instance - 运行时实例，owner - 被施加效果的实体节点，delta - 本帧间隔
func on_tick(_instance: StatusEffectInstance, _owner: Node2D, _delta: float) -> void:
	pass

## 功能：效果移除时调用（手动移除、超时、死亡等）
## 参数：instance - 运行时实例，owner - 被施加效果的实体节点
func on_remove(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

## 功能：获取该策略提供的速度倍率修正（默认无修正）
## 返回值：乘算倍率，如 0.7 表示减速 30%
func get_speed_multiplier(_instance: StatusEffectInstance) -> float:
	return 1.0

## 功能：获取该策略提供的伤害倍率修正（默认无修正）
## 返回值：乘算倍率，如 1.2 表示增伤 20%
func get_damage_multiplier(_instance: StatusEffectInstance) -> float:
	return 1.0

## 功能：是否阻止移动（眩晕等控制效果覆写此方法）
## 返回值：true 表示实体不可移动
func is_stun(_instance: StatusEffectInstance) -> bool:
	return false

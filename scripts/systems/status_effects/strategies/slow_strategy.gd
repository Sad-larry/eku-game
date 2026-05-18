# ==============================================================================
#   slow_strategy.gd
#   功能：减速策略。施加后降低实体移动速度，移除后恢复。
# ==============================================================================
class_name SlowStrategy extends StatusEffectStrategy

# ========================== 虚方法覆写 ==========================
func on_apply(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

func on_remove(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

func get_speed_multiplier(instance: StatusEffectInstance) -> float:
	return instance.effect_type.strategy_params.get("speed_multiplier", 0.7)

# ==============================================================================
#   buff_strategy.gd
#   功能：属性增益策略。施加后修改实体属性（速度、伤害等），移除后恢复。
# ==============================================================================
class_name BuffStrategy extends StatusEffectStrategy

# ========================== 虚方法覆写 ==========================
func on_apply(instance: StatusEffectInstance, _owner: Node2D) -> void:
	# Buff 效果无需即时逻辑，属性修正通过 get_speed_multiplier / get_damage_multiplier 查询
	instance.user_data["applied"] = true

func on_remove(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	# 属性修正自动失效（Component 每帧重新汇总）
	pass

func get_speed_multiplier(instance: StatusEffectInstance) -> float:
	return instance.effect_type.strategy_params.get("speed_multiplier", 1.0)

func get_damage_multiplier(instance: StatusEffectInstance) -> float:
	return instance.effect_type.strategy_params.get("damage_multiplier", 1.0)

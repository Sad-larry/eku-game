# ==============================================================================
#   stun_strategy.gd
#   功能：眩晕策略。施加后阻止实体移动和攻击。
# ==============================================================================
class_name StunStrategy extends StatusEffectStrategy

# ========================== 虚方法覆写 ==========================
func on_apply(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

func on_remove(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

func is_stun(_instance: StatusEffectInstance) -> bool:
	return true

func get_speed_multiplier(_instance: StatusEffectInstance) -> float:
	return 0.0

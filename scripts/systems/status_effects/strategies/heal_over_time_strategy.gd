# ==============================================================================
#   heal_over_time_strategy.gd
#   功能：持续回复（HOT）策略。按 tick_interval 恢复实体生命值。
# ==============================================================================
class_name HealOverTimeStrategy extends StatusEffectStrategy

# ========================== 虚方法覆写 ==========================
func on_apply(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

func on_tick(instance: StatusEffectInstance, owner: Node2D, _delta: float) -> void:
	var heal_per_tick: int = instance.effect_type.strategy_params.get("heal_per_tick", 2)
	var health_component: HealthComponent = owner.get_node_or_null("StatsComponents/HealthComponent")
	if health_component == null:
		health_component = owner.get_node_or_null("Stats/HealthComponent")
	if health_component and health_component.current_health < health_component.max_health:
		health_component.heal(heal_per_tick * instance.stacks)

func on_remove(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

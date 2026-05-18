# ==============================================================================
#   dot_strategy.gd
#   功能：持续伤害（DOT）策略。按 tick_interval 对实体造成伤害。
# ==============================================================================
class_name DotStrategy extends StatusEffectStrategy

# ========================== 虚方法覆写 ==========================
func on_apply(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

func on_tick(instance: StatusEffectInstance, owner: Node2D, _delta: float) -> void:
	var damage_per_tick: int = instance.effect_type.strategy_params.get("damage_per_tick", 1)
	var health_component: HealthComponent = owner.get_node_or_null("StatsComponents/HealthComponent")
	if health_component == null:
		# Player 节点路径不同
		health_component = owner.get_node_or_null("Stats/HealthComponent")
	if health_component and health_component.current_health > 0:
		health_component.take_damage(damage_per_tick * instance.stacks)

func on_remove(_instance: StatusEffectInstance, _owner: Node2D) -> void:
	pass

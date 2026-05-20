# ==============================================================================
#   aoe_attack_behavior.gd
#   功能：AOE 攻击行为。定期在自身位置释放范围伤害。
# ==============================================================================
class_name AoeAttackBehavior extends TriggerableBehavior

@export var aoe_radius: float = 100.0
@export var aoe_damage: int = 5
@export var status_effect: StatusEffectType

func _execute_behavior() -> void:
	if enemy == null:
		return

	var player := enemy.get_target()
	if player == null:
		return

	if enemy.global_position.distance_to(player.global_position) <= aoe_radius:
		if player.health_component:
			player.health_component.take_damage(aoe_damage)
		if status_effect and player.status_effect_component:
			player.status_effect_component.apply_effect(status_effect, enemy)

	if Global.DEBUG_MODE:
		print("[AoeAttackBehavior] AOE 攻击，伤害: ", aoe_damage)

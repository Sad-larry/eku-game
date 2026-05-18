# ==============================================================================
#   aoe_attack_behavior.gd
#   功能：AOE 攻击行为。定期在自身位置释放范围伤害。
# ==============================================================================
class_name AoeAttackBehavior extends EnemyBehavior

@export var aoe_radius: float = 100.0
@export var aoe_damage: int = 5
@export var aoe_interval: float = 4.0
@export var status_effect: StatusEffectType

var _attack_timer: float = 0.0

func _on_setup() -> void:
	_attack_timer = aoe_interval

func _on_update(delta: float) -> void:
	if enemy == null or not enemy.player_detected:
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = aoe_interval
		_execute_aoe()

func _execute_aoe() -> void:
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

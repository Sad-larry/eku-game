# attack_state.gd
extends EnemyState
class_name EnemyAttackState

var _performed: bool = false

func enter() -> void:
	_performed = false
	play_animation("attack")
	# 执行攻击（可交给 Enemy.attack() 或 AttackComponent）
	_enemy.attack()
	_performed = true
	# 攻击后立即进入冷却
	state_machine.change_to("cooldown")

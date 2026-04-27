# cooldown_state.gd
extends EnemyState
class_name EnemyCooldownState

var _timer: float = 0.0

func enter() -> void:
	_timer = _enemy.attack_cooldown

func update(_delta):
	_timer -= _delta
	if _timer <= 0.0:
		state_machine.change_to("chase")

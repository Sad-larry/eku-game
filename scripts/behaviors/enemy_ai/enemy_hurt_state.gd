# hurt_state.gd
extends EnemyState
class_name EnemyHurtState

var _timer: float = 0.0

func enter() -> void:
	play_animation("hurt")
	_timer = _enemy.hurt_duration    # 配置来自 Enemy 实体

func update(_delta):
	_timer -= _delta
	if _timer <= 0.0:
		# 根据玩家是否在范围内，切换 chase / idle
		state_machine.change_to(
			"chase" if is_player_in_range(_enemy.detection_range) else "idle"
			)

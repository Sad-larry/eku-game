# idle_state.gd
extends EnemyState
class_name EnemyIdleState

func enter() -> void:
	play_animation("idle")

func update(_delta):
	# 距离检测 → 通过 state_machine.change_to("chase")
	if is_player_in_range(_enemy.detection_range):
		state_machine.change_to("chase")

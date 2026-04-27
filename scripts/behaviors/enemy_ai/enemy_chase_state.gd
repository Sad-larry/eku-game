# chase_state.gd
extends EnemyState
class_name EnemyChaseState

func enter() -> void:
	play_animation("run")

func physics_update(_delta):
	# 1. 获取方向、设置 velocity
	# 2. move_and_slide()
	# 3. 距离判断 → chase / attack / idle
	pass

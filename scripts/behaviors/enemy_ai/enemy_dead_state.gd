extends EnemyState
class_name EnemyDeadState


func enter() -> void:
	play_animation("dead")
	# 禁用碰撞、停止移动
	# 延迟销毁或播放死亡特效
	#await get_tree().create_timer(1.5).timeout
	_enemy.queue_free()

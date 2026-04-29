# ==============================================================================
#   chase_state.gd
#   功能：敌人追击状态，持续追踪目标玩家，根据距离判断是否切换为攻击或待机状态，
#        并控制移动逻辑。
# ==============================================================================
extends EnemyState
class_name EnemyChaseState

# ========================== 状态生命周期模块 ==========================
## 功能：进入追击状态时播放奔跑动画
func enter() -> void:
	play_animation("run")

## 功能：每物理帧更新，处理追击逻辑与状态切换判断
## 参数：delta (float) - 物理帧间隔时间（秒）
func physics_update(delta: float) -> void:
	# 获取当前追击目标
	var target: Node2D = _enemy.get_target()
	if target == null:
		# 无目标时切换到待机状态
		state_machine.send_event("idle")
		return

	# 计算朝向目标的单位方向向量和距离
	var direction: Vector2 = (target.global_position - _enemy.global_position).normalized()
	var dist: float = _enemy.global_position.distance_to(target.global_position)

	# 判断是否进入攻击范围
	if dist <= _enemy.attack_range:
		_enemy.movement.stop_immediately()
		state_machine.send_event("attack")
		return

	# 判断是否脱离索敌范围
	if dist > _enemy.detection_range:
		_enemy.movement.stop_immediately()
		state_machine.send_event("idle")
		return

	# 在追击范围内：向目标方向移动
	_enemy.movement.move_toward(direction, delta)
	_enemy.move_and_slide()

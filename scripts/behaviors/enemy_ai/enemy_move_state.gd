# ==============================================================================
#   move_state.gd
#   功能：敌人移动（追击）状态，控制移动逻辑。
# ==============================================================================
extends EnemyState
class_name EnemyMoveState

# ========================== 状态生命周期模块 ==========================
## 功能：进入追击状态时播放奔跑动画
func enter() -> void:
	get_anim().play_state("move")


## 功能：移动状态中接收到事件时的回调
func on_event(event_name: String) -> void:
	match event_name:
		"idle":
			state_machine.change_to("idle")
		"attack":
			state_machine.change_to("attack")
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")
		"skill":
			state_machine.change_to("skill")

## 功能：每物理帧更新，处理追击逻辑与状态切换判断
## 参数：delta (float) - 物理帧间隔时间（秒）
## 功能：每物理帧更新，处理追击逻辑与状态切换判断
func physics_update(delta: float) -> void:
	var target: Node2D = _enemy.get_target()
	if target == null:
		get_movement().stop_immediately()
		state_machine.send_event("idle")
		return
	
	var direction: Vector2 = (target.global_position - _enemy.global_position).normalized()
	var dist: float = _enemy.global_position.distance_to(target.global_position)
	
	# 进入攻击范围
	if dist <= _enemy.get_attack_range():
		get_movement().stop_immediately()
		state_machine.send_event("attack")
		return
	
	# 脱离检测范围（用 VisionArea+player_detected 更准确，此处做备选兜底）
	if not _enemy.player_detected:
		get_movement().stop_immediately()
		state_machine.send_event("idle")
		return
	
	# 追击中
	get_movement().move_toward(direction, delta)
	_enemy.move_and_slide()

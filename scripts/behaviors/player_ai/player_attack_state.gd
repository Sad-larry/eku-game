# ==============================================================================
#   attack_state.gd
#   功能：玩家攻击状态，进入时播放攻击动画、触发攻击组件判定、禁止移动，
#        攻击结束后根据输入缓冲或移动输入切换至技能/移动/待机状态。
# ==============================================================================
extends PlayerState
class_name PlayerAttackState

# ========================== 内部变量模块 ==========================
## 攻击状态持续计时器（秒），用于控制攻击动画持续时间
var _attack_timer: float = 0.0

# ========================== 状态生命周期模块 ==========================
## 功能：进入攻击状态时触发攻击逻辑、播放动画并初始化计时器
func enter() -> void:
	get_anim().play_state("attack")
	get_movement().stop_immediately()
	_player.attack_component.start_attack("light_attack", 1.0)
	_attack_timer = 1.0

## 功能：每帧更新，倒计时攻击时长，结束后检查输入缓冲并切换状态
## 参数：delta (float) - 帧间隔时间（秒）
func update(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		# 攻击动画播放完毕，先检查缓冲队列中是否有下一个动作
		var next_action = InputManager.get_buffered_input()
		if next_action:
			# 若缓冲输入为技能动作，则切换到技能状态
			if next_action in ["skill_1", "skill_2", "skill_3", "skill_4"]:
				_transition_to_skill(next_action)
			else:
				state_machine.change_to(next_action)
			return
		else:
			# 无缓冲输入，根据当前移动输入决定切换至移动或待机状态
			if InputManager.get_movement_vector() != Vector2.ZERO:
				state_machine.change_to("move")
			else:
				state_machine.change_to("idle")

# ========================== 事件处理模块 ==========================
## 功能：攻击状态中接收到事件时的回调
## 参数：event_name (String) - 事件名称
## 说明：攻击状态忽略大部分输入，仅允许受击（hurt）、技能、死亡事件打断
func on_event(event_name: String) -> void:
	match event_name:
		"hurt":
			# 受击优先级高于攻击，允许被打断
			state_machine.change_to("hurt")
		"skill_1", "skill_2", "skill_3", "skill_4":
			_transition_to_skill(event_name)
		"dead":
			state_machine.change_to("dead")

# ========================== 状态行为模块 ==========================
## 功能：判断当前状态是否允许移动
## 返回值：bool - 攻击状态下禁止移动，返回 false
func is_movement_allowed() -> bool:
	return false

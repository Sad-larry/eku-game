extends PlayerState
class_name PlayerRecoveryState

var _recovery_timer: float = 0.0
var _skill_data: SkillEffect = null

func enter() -> void:
	# 从 skill_data 读取后摇时长
	if _skill_data:
		_recovery_timer = _skill_data.recovery_duration
	else:
		# 防御：没有 skill_data 时立即结束
		_recovery_timer = 0.0
	
	# 如果有后摇动画则播放，否则保持 idle 状态
	if _recovery_timer > 0.0:
		_player.anim_controller.play_state("recovery")
	# 如果 recovery_duration = 0.0，update() 会在第一帧直接进入下一步

func update(delta: float) -> void:
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		# 后摇结束 → 检查输入缓冲
		var next_action = InputManager.get_buffered_input()
		if next_action:
			# 将技能动作名转为技能数据注入 skill state
			if next_action in ["skill_1", "skill_2", "skill_3", "skill_4"]:
				_transition_to_skill(next_action)
			else:
				# 非技能动作（如 attack）直接切换
				state_machine.change_to(next_action)
			return
		
		# 无缓冲 → 根据移动输入决定 idle 或 move
		if InputManager.get_movement_vector() != Vector2.ZERO and \
		   _player.player_state_machine.current_state_name in ["recovery"]:
			state_machine.change_to("move")
		else:
			state_machine.change_to("idle")

func on_event(event_name: String) -> void:
	match event_name:
		"skill_1", "skill_2", "skill_3", "skill_4":
			# 后摇期间按了技能键 → 当前动作已经被 InputManager 缓冲了
			# 这里不需要做任何事，update() 中 timer 到期后会通过 get_buffered_input() 消费
			pass
		"hurt":
			# 后摇可以被受击打断
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")

# 外部注入技能数据（由 PlayerSkillState 在 transition 前调用）
func set_skill_data(data: SkillEffect) -> void:
	_skill_data = data

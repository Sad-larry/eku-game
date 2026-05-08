# ==============================================================================
#   PlayerRecoveryState.gd
#   功能：玩家技能后摇状态，在技能释放结束后进入，等待技能的后摇时长，
#        期间可被受击/死亡打断，后摇结束后检查输入缓冲并切换至对应状态。
# ==============================================================================
extends PlayerState
class_name PlayerRecoveryState

# ========================== 内部变量模块 ==========================
## 后摇剩余计时器（秒）
var _recovery_timer: float = 0.0

## 当前技能数据（用于读取后摇时长）
var _skill_data: SkillEffect = null

# ========================== 状态生命周期模块 ==========================
## 功能：进入后摇状态时，从技能数据中读取后摇时长并播放后摇动画
func enter() -> void:
	# 从 skill_data 读取后摇时长
	if _skill_data:
		_recovery_timer = _skill_data.recovery_duration
		
		# 在进入后摇时开始技能冷却（冷却与后摇重叠）
		var runner = _player.get_skill_runner(_skill_data.id)
		if runner:
			runner.start_cooldown()
	else:
		# 防御性代码：没有 skill_data 时立即结束后摇
		_recovery_timer = 0.0
	
	# 若有后摇动画则播放，否则保持当前动画（如 idle）
	if _recovery_timer > 0.0:
		_player.anim_controller.play_state("recovery")
	# 若 recovery_duration = 0.0，update() 会在第一帧直接进入下一步

## 功能：每帧更新，倒计时后摇时长，结束后检查输入缓冲并切换状态
## 参数：delta (float) - 帧间隔时间（秒）
func update(delta: float) -> void:
	# 暂停状态下不推进后摇计时
	if get_tree() and get_tree().paused:
		return
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		# 后摇结束 -> 检查输入缓冲队列
		var next_action = InputManager.get_buffered_input()
		if next_action:
			# 若缓冲输入为技能动作，则切换到技能状态
			if next_action in ["skill_1", "skill_2", "skill_3", "skill_4"]:
				var data = _player.get_skill_data_by_action(next_action)
				if data:
					var runner = _player.get_skill_runner(data.id)
					if runner and runner.is_ready():
						_transition_to_skill(next_action)
						return
				# 冷却中或找不到 runner -> 忽略缓冲，继续后续逻辑
			else:
				# 非技能动作（如 attack）直接切换
				state_machine.change_to(next_action)
				return
		
		# 无缓冲输入 -> 根据移动输入决定切换到移动或待机状态
		if InputManager.get_movement_vector() != Vector2.ZERO:
			state_machine.change_to("move")
		else:
			state_machine.change_to("idle")

# ========================== 事件处理模块 ==========================
## 功能：后摇状态中接收到事件时的回调
## 参数：event_name (String) - 事件名称
func on_event(event_name: String) -> void:
	match event_name:
		"skill_1", "skill_2", "skill_3", "skill_4":
			# 后摇期间按下的技能键，已由 InputManager 缓冲
			# 此处无需额外处理，update() 中计时器到期后会通过 get_buffered_input() 消费缓冲
			pass
		"hurt":
			# 后摇可以被受击事件打断
			state_machine.change_to("hurt")
		"dead":
			# 后摇可以被死亡事件打断
			state_machine.change_to("dead")
			
# ========================== 状态行为模块 ==========================
## 功能：后摇期间禁止移动
## 返回值：bool - false 表示禁止移动
func is_movement_allowed() -> bool:
	return false
	
# ========================== 公共 API 模块 ==========================
## 功能：外部注入技能数据（由 PlayerSkillState 在切换状态前调用）
## 参数：data (SkillEffect) - 当前释放的技能数据资源
func set_skill_data(data: SkillEffect) -> void:
	_skill_data = data

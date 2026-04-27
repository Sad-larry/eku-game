extends PlayerState
class_name PlayerSkillState

# 当前执行的技能数据
var _skill_data: SkillEffect = null
# 主动画阶段持续时间（秒）
var _active_timer: float = 0.0

func enter() -> void:
	if not _skill_data:
		state_machine.change_to("idle")
		return
	# 使用技能数据驱动动画播放
	var dir = _player.last_direction
	# 1. 播放技能动画
	_player.anim_controller.play_skill_animation(_skill_data.anim_base_name, dir)
	# 2. 停止移动
	_player.movement_component.stop_immediately()
	# 3. 初始化定时器（从技能数据获取主动画时长）
	_active_timer = _skill_data.skill_duration
	# 4. 执行技能逻辑（通过 SkillRunner）
	_execute_skill()
	

func update(delta: float) -> void:
	_active_timer -= delta
	if _active_timer <= 0.0:
		# 主动画结束 → 进入后摇
		# 把 skill_data 传给 recovery state
		var recovery_state = state_machine.get_state("recovery") as PlayerRecoveryState
		if recovery_state:
			recovery_state.set_skill_data(_skill_data)
		state_machine.change_to("recovery")

# 外部注入技能数据（由 InputManager 触发时调用，或被缓冲消费时调用）
func setup_skill(data: SkillEffect) -> void:
	_skill_data = data

# 执行技能的实际效果
func _execute_skill() -> void:
	if not _skill_data:
		return
	# 从 Player 的持久化池里拿 Runner，不 new 了
	var runner = _player.get_skill_runner(_skill_data.id)
	if runner and runner.is_ready():
		runner.execute(_player.get_target())
	elif runner:
		print("技能 %s 尚未冷却" % _skill_data.name)
		# 冷却中 → 回到 idle
		state_machine.change_to("idle")
	else:
		print("找不到技能 %s 的 Runner" % _skill_data.id)
		state_machine.change_to("idle")


func on_event(event_name: String) -> void:
	match event_name:
		"hurt":
			# 技能可以被受击打断
			state_machine.change_to("hurt")
		# 其他技能事件不处理（它们会被 InputManager 缓冲）

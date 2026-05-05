# ==============================================================================
#   PlayerSkillState.gd
#   功能：玩家技能释放状态，由技能数据驱动，负责播放技能动画、消耗能量、
#        执行技能逻辑（通过 SkillRunner），技能主动画结束后自动切换至后摇状态。
#        释放期间可被受击/死亡事件打断。
# ==============================================================================
extends PlayerState
class_name PlayerSkillState

# ========================== 内部变量模块 ==========================
## 当前释放的技能数据资源
var _skill_data: SkillEffect = null

## 主动画阶段持续时间（秒），从技能数据中读取
var _active_timer: float = 0.0

# ========================== 状态生命周期模块 ==========================
## 功能：进入技能状态时，验证技能数据、播放技能动画、停止移动、初始化计时器并执行技能逻辑
func enter() -> void:
	# 技能数据有效性检查
	if not _skill_data:
		state_machine.change_to("idle")
		return
		
	# 尝试执行技能逻辑（内部包含所有校验与消耗）
	if not _execute_skill():
		# 失败时 _execute_skill 已切换状态，直接返回
		state_machine.change_to("idle")
		return
		
	# 使用技能数据驱动动画播放（根据玩家最后一次移动方向确定朝向）
	var dir = _player.last_direction
	# 1. 使用直接播放方式播放技能动画（技能基础名称 + 方向）
	_player.anim_controller.play_skill_directly(_skill_data.anim_base_name, dir)
	# 2. 立即停止移动
	_player.movement_component.stop_immediately()
	# 3. 初始化主动画计时器（从技能数据获取时长）
	_active_timer = _skill_data.skill_duration

## 功能：退出技能状态时恢复 AnimationTree 控制权
func exit() -> void:
	super()
	_player.anim_controller.restore_anim_tree()

## 功能：每帧更新，倒计时主动画时长，结束后切换至后摇状态
## 参数：delta (float) - 帧间隔时间（秒）
func update(delta: float) -> void:
	# 暂停状态下不推进技能计时
	if get_tree() and get_tree().paused:
		return
	# 已经结束了，防止重复触发
	if _active_timer <= 0.0:
		return
	_active_timer -= delta
	if _active_timer <= 0.0:
		# 先恢复 AnimationTree 再切换状态，确保后摇能正确控制动画
		_player.anim_controller.restore_anim_tree()
		# 主动画结束 → 进入后摇状态
		var recovery_state = state_machine.get_state("recovery") as PlayerRecoveryState
		if recovery_state:
			# 将当前技能数据传递给后摇状态（用于读取后摇时长）
			recovery_state.set_skill_data(_skill_data)
		state_machine.change_to("recovery")

# ========================== 事件处理模块 ==========================
## 功能：技能状态中接收到事件时的回调
## 参数：event_name (String) - 事件名称
func on_event(event_name: String) -> void:
	match event_name:
		"hurt":
			# 技能可以被受击事件打断
			state_machine.change_to("hurt")
		"dead":
			# 技能可以被死亡事件打断
			state_machine.change_to("dead")
		# 其他技能事件（如再次按技能键）不处理，它们会被 InputManager 缓冲
		# 等待技能结束后由后摇状态消费缓冲队列

# ========================== 状态行为模块 ==========================
## 功能：技能释放期间禁止移动
## 返回值：bool - false 表示禁止移动
func is_movement_allowed() -> bool:
	return false

# ========================== 公共 API 模块 ==========================
## 功能：外部注入技能数据（由状态机在切换前调用）
## 参数：data (SkillEffect) - 技能数据资源
func setup_skill(data: SkillEffect) -> void:
	_skill_data = data

# ========================== 内部辅助方法模块 ==========================
## 功能：执行技能的实际效果（能量消耗 + 技能运行器执行）
## 返回值：bool - true 表示技能释放成功
func _execute_skill() -> bool:
	# 从玩家的持久化技能运行器池中获取对应的运行器
	var runner = _player.get_skill_runner(_skill_data.id)
	if not runner:
		# 未找到对应的技能运行器
		print("找不到技能 %s 的 Runner" % _skill_data.id)
		return false
	if not runner.is_ready():
		# 技能处于冷却中
		print("技能 %s 尚未冷却" % _skill_data.name)
		return false
	
	# 获取玩家能量组件
	var energy: EnergyComponent = _player.energy_component
	# 能量不足检查
	if energy.current_energy < _skill_data.energy_cost:
		# 能量不足，技能无法释放，回到待机状态
		print("能量不足，需要: ", _skill_data.energy_cost)
		return false
	# 消耗能量
	energy.consume(_skill_data.energy_cost)
	# 执行技能，不立即开始冷却
	var success = runner.execute(_player.get_target(), false)
	if not success:
		# 执行失败 → 退还能量
		energy.add(_skill_data.energy_cost)   # 需在 EnergyComponent 实现 add()
		print("技能执行失败，已退还能量")
		return false
	return true

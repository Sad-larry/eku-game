# ==============================================================================
#   player_skill_state.gd
#   功能：玩家技能释放状态，由技能数据驱动播放动画、消耗能量、执行技能逻辑。
#        冷却由后摇状态（PlayerRecoveryState）统一启动，避免双重冷却。
# ==============================================================================
extends PlayerState
class_name PlayerSkillState

var _skill_data: SkillEffect = null
var _active_timer: float = 0.0

func enter() -> void:
	if not _skill_data:
		state_machine.change_to("idle")
		return

	if not _execute_skill():
		state_machine.change_to("idle")
		return

	var dir := player.last_direction
	get_anim().play_skill(_skill_data.anim_base_name, dir)
	get_movement().stop_immediately()
	_active_timer = _skill_data.skill_duration

	# 技能持续时间为 0 时，立即进入后摇状态
	if _active_timer <= 0.0:
		_transition_to_recovery()

func update(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if _active_timer <= 0.0:
		return
	_active_timer -= delta
	if _active_timer <= 0.0:
		_transition_to_recovery()

func _transition_to_recovery() -> void:
	var recovery_state := state_machine.get_state("recovery") as PlayerRecoveryState
	if recovery_state:
		recovery_state.set_skill_data(_skill_data)
	state_machine.change_to("recovery")

func on_event(event_name: String) -> void:
	match event_name:
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")

func is_movement_allowed() -> bool:
	return false

func setup_skill(data: SkillEffect) -> void:
	_skill_data = data

func _execute_skill() -> bool:
	var runner := player.skill_manager.get_runner(_skill_data.id)
	if not runner:
		print("找不到技能 %s 的 Runner" % _skill_data.id)
		return false
	if not runner.is_ready():
		print("技能 %s 尚未冷却" % _skill_data.name)
		return false

	var energy := player.energy_component
	if energy.current_energy < _skill_data.energy_cost:
		print("能量不足，需要: ", _skill_data.energy_cost)
		return false
	var pre_energy := energy.current_energy
	energy.consume(_skill_data.energy_cost)
	var actual_cost := pre_energy - energy.current_energy
	# 传递 auto_cooldown = false，冷却由后摇状态的 start_cooldown 统一管理
	var success := runner.execute(null, false)
	if not success:
		energy.add(actual_cost)
		print("技能执行失败，已退还能量")
		return false
	return true

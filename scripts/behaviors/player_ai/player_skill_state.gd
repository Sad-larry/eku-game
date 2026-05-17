# ==============================================================================
#   player_skill_state.gd
#   功能：玩家技能释放状态。职责仅限：
#         - 播放技能动画（非锁定时仅播放起手动画，然后切回 idle/move）
#         - 决定玩家在技能期间能否移动（由技能数据 can_move_while_casting 决定）
#         - 被打断时通知 SkillRunner 处理逻辑后果，自身只做动画切换
#   注意：skill_duration 是技能效果在世界的存在时长（如 buff 持续5秒），
#         不由状态机管理。状态机只管理"起手动画锁定时间"：
#         - can_move_while_casting = true  → 短锁定（0.3s 起手动画），之后切回 idle/move
#         - can_move_while_casting = false → 锁定 skill_duration 作为施法/动画时长
#   不做：
#         - 能量检查（由 Player 层执行）
#         - 冷却检查（由 Player 层执行）
#         - 能量消耗（由 Player 层执行）
#         - 技能逻辑处理（由 SkillRunner + 技能脚本负责）
# ==============================================================================
extends PlayerState
class_name PlayerSkillState

## 可移动释放技能的起手锁定时间（秒），足够播放一次起手动画
const CAST_LOCK_DURATION: float = 0.3

var _skill_data: SkillEffect = null
var _active_timer: float = 0.0

func enter() -> void:
	if not _skill_data:
		state_machine.change_to("idle")
		return

	var dir := player.last_direction
	get_anim().play_skill(_skill_data.anim_base_name, dir)
	get_movement().stop_immediately()

	# 锁定时间：可移动释放只锁定起手动画，不可移动释放锁定整个 skill_duration
	if _skill_data.can_move_while_casting:
		_active_timer = CAST_LOCK_DURATION
	else:
		_active_timer = _skill_data.skill_duration

	if _active_timer <= 0.0:
		state_machine.change_to("idle")

func update(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if _active_timer <= 0.0:
		return
	_active_timer -= delta
	if _active_timer <= 0.0:
		state_machine.change_to("idle")

func on_event(event_name: String) -> void:
	match event_name:
		"hurt":
			_notify_runner_interrupted()
			state_machine.change_to("hurt")
		"dead":
			_notify_runner_interrupted()
			state_machine.change_to("dead")

func is_movement_allowed() -> bool:
	return _skill_data and _skill_data.can_move_while_casting

func setup_skill(data: SkillEffect) -> void:
	_skill_data = data

func get_skill_data() -> SkillEffect:
	return _skill_data

func get_move_speed_multiplier() -> float:
	return _skill_data.move_speed_multiplier if _skill_data else 1.0

func _notify_runner_interrupted() -> void:
	if not _skill_data:
		return
	var runner := player.skill_manager.get_runner(_skill_data.id)
	if runner:
		runner.on_interrupted()

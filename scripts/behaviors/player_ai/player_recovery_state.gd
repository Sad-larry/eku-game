# ==============================================================================
#   player_recovery_state.gd
#   功能：玩家技能后摇状态，等待后摇时长后检查输入缓冲并切换状态。
# ==============================================================================
extends PlayerState
class_name PlayerRecoveryState

var _recovery_timer: float = 0.0
var _skill_data: SkillEffect = null

func enter() -> void:
	if _skill_data:
		_recovery_timer = _skill_data.recovery_duration
		var runner := player.skill_manager.get_runner(_skill_data.id)
		if runner:
			runner.start_cooldown()
	else:
		_recovery_timer = 0.0

	if _recovery_timer > 0.0:
		get_anim().play_anim("recovery", player.last_direction)

func update(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		var next_action := InputManager.get_buffered_input()
		if next_action:
			if next_action in ["skill_1", "skill_2", "skill_3", "skill_4"]:
				var data := player.skill_manager.get_data_by_action(next_action)
				if data:
					var runner := player.skill_manager.get_runner(data.id)
					if runner and runner.is_ready():
						_transition_to_skill(next_action)
						return
			else:
				state_machine.change_to(next_action)
				return

		if InputManager.get_movement_vector() != Vector2.ZERO:
			state_machine.change_to("move")
		else:
			state_machine.change_to("idle")

func on_event(event_name: String) -> void:
	match event_name:
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")

func is_movement_allowed() -> bool:
	return false

func set_skill_data(data: SkillEffect) -> void:
	_skill_data = data

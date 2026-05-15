# ==============================================================================
#   player_attack_state.gd
#   功能：玩家攻击状态，播放攻击动画、触发攻击判定、禁止移动，
#        攻击结束后检查输入缓冲并切换至下一状态。
# ==============================================================================
extends PlayerState
class_name PlayerAttackState

var _attack_timer: float = 0.0

func enter() -> void:
	get_anim().play_anim("attack", player.last_direction)
	get_movement().stop_immediately()
	_attack_timer = 1.0

func update(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		var next_action := InputManager.get_buffered_input()
		if next_action:
			if next_action in ["skill_1", "skill_2", "skill_3", "skill_4"]:
				_transition_to_skill(next_action)
			else:
				state_machine.change_to(next_action)
			return
		else:
			if InputManager.get_movement_vector() != Vector2.ZERO:
				state_machine.change_to("move")
			else:
				state_machine.change_to("idle")

func on_event(event_name: String) -> void:
	match event_name:
		"hurt":
			state_machine.change_to("hurt")
		"skill_1", "skill_2", "skill_3", "skill_4":
			_transition_to_skill(event_name)
		"dead":
			state_machine.change_to("dead")

func is_movement_allowed() -> bool:
	return false

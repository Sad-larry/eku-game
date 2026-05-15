# ==============================================================================
#   player_idle_state.gd
#   功能：玩家待机状态，播放待机动画，响应移动/攻击/受击/死亡/技能事件。
# ==============================================================================
extends PlayerState
class_name PlayerIdleState

func enter() -> void:
	get_anim().play_anim("idle", player.last_direction)

func on_event(event_name: String) -> void:
	match event_name:
		"move":
			state_machine.change_to("move")
		"attack":
			state_machine.change_to("attack")
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")
		"skill_1", "skill_2", "skill_3", "skill_4":
			_transition_to_skill(event_name)

# player/states/move_state.gd
extends PlayerState
class_name PlayerMoveState

func enter() -> void:
	_player.anim_controller.play_state("move")

func on_event(event_name: String) -> void:
	match event_name:
		"idle":
			state_machine.change_to("idle")
		"attack":
			state_machine.change_to("attack")
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")
		"skill_1", "skill_2", "skill_3", "skill_4":
			_transition_to_skill(event_name)

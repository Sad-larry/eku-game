# player/states/idle_state.gd
extends PlayerState
class_name PlayerIdleState

func enter() -> void:
	_player.anim_controller.play_state("idle")
	#player.movement_component.stop_immediately()

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

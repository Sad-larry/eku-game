# player/states/hurt_state.gd
extends PlayerState
class_name PlayerHurtState

var _hurt_duration: float = 0.2
var _timer: float = 0.0

func enter() -> void:
	_timer = _hurt_duration
	_player.anim_controller.play_state("hurt")

func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.change_to("idle")
		return
		
func on_event(_event_name: String) -> void:
	pass  # 受击状态不可打断

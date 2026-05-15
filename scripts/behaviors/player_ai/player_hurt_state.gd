# ==============================================================================
#   player_hurt_state.gd
#   功能：玩家受击硬直状态，播放受击动画，持续固定时长后自动回到待机。
# ==============================================================================
extends PlayerState
class_name PlayerHurtState

var _hurt_duration: float = 0.2
var _timer: float = 0.0

func enter() -> void:
	_timer = _hurt_duration
	get_anim().play_anim("hurt", player.last_direction)

func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.change_to("idle")

func on_event(_event_name: String) -> void:
	pass

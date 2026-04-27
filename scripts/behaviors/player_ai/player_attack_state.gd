# player/states/attack_state.gd
extends PlayerState
class_name PlayerAttackState

var _attack_timer: float = 0.0

func enter() -> void:
	_player.anim_controller.play_state("attack")
	_player.movement_component.stop_immediately()
	_player.attack_component.start_attack("light_attack", 1.0)
	_attack_timer = 1.0

func update(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		# 攻击动画播完 → 先看缓冲里有没有下一个动作
		var next_action = InputManager.get_buffered_input()
		if next_action:
			if next_action in ["skill_1", "skill_2", "skill_3", "skill_4"]:
				_transition_to_skill(next_action)
			else:
				state_machine.change_to(next_action)
			return
		else:
			# 无缓冲 → 根据移动输入决定 idle 或 move
			if InputManager.get_movement_vector() != Vector2.ZERO:
				state_machine.change_to("move")
			else:
				state_machine.change_to("idle")

# 攻击状态忽略所有输入事件，防止被中途打断
func on_event(event_name: String) -> void:
	# 可选：允许 hurt 打断攻击（受击优先级高于攻击）
	match event_name:
		"hurt":
			state_machine.change_to("hurt")
		"skill_1", "skill_2", "skill_3", "skill_4":
			_transition_to_skill(event_name)
		"dead":
			state_machine.change_to("dead")

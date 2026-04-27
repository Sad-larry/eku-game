extends FSMState
class_name PlayerState

## 玩家引用（可根据实际类型调整）
var _player: Player

func setup(p: Player) -> void:
	_player = p
	# 确保组件引用正确（也可在 enter 中每次获取）

func get_anim() -> PlayerAnimationController:
	return _player.anim_controller

func get_movement() -> MovementComponent:
	return _player.movement_component

func _transition_to_skill(action_name: String) -> void:
	var data = _player.get_skill_data_by_action(action_name)
	var skill_state = state_machine.get_state("skill") as PlayerSkillState
	skill_state.setup_skill(data)
	state_machine.change_to("skill")

# ==============================================================================
#   player_state.gd
#   功能：玩家状态基类，为所有玩家具体状态提供通用辅助方法。
# ==============================================================================
extends FSMState
class_name PlayerState

# ========================== 变量定义模块 ==========================
## 玩家实体引用（由状态机在 _ready 中注入）
var player: Player

# ========================== 导出变量模块 ==========================
## 状态机名称（在场景中设置，如 "idle"、"move"）
@export var state_name: String = ""

# ========================== 辅助方法模块 ==========================
## 功能：获取玩家的动画控制器
## 返回值：PlayerAnimationController - 玩家动画控制器实例
func get_anim() -> PlayerAnimationController:
	return player.anim_controller

## 功能：获取玩家的移动组件
## 返回值：PlayerMovementComponent - 玩家移动组件实例
func get_movement() -> PlayerMovementComponent:
	return player.movement_component

## 功能：根据输入动作名称切换到对应的技能状态
## 参数：action_name (String) - 输入动作名称（如 "skill_1"）
func _transition_to_skill(action_name: String) -> void:
	var data := player.skill_manager.get_data_by_action(action_name)
	if data == null:
		return
	var skill_state := state_machine.get_state("skill") as PlayerSkillState
	if skill_state:
		skill_state.setup_skill(data)
		state_machine.change_to("skill")

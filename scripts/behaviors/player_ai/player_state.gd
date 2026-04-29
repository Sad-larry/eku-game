# ==============================================================================
#   PlayerState.gd
#   功能：玩家状态基类，继承自 FSMState，为所有玩家具体状态（待机、移动、攻击、受击、
#        死亡、后摇、技能等）提供通用的辅助方法（获取玩家引用、动画控制器、移动组件，
#        以及技能切换辅助方法），减少子类重复代码。
# ==============================================================================
extends FSMState
class_name PlayerState

# ========================== 变量定义模块 ==========================
## 玩家实体引用（需通过 setup() 方法注入）
var _player: Player

# ========================== 公共 API 模块 ==========================
## 功能：设置玩家引用，供状态机初始化时调用
## 参数：p (Player) - 玩家实体实例
func setup(p: Player) -> void:
	_player = p
	# 组件引用可通过 getter 方法按需获取，也可在 setup 中预先缓存

## 功能：获取玩家的动画控制器组件
## 返回值：PlayerAnimationController - 动画控制器实例
func get_anim() -> PlayerAnimationController:
	return _player.anim_controller

## 功能：获取玩家的移动组件
## 返回值：PlayerMovementComponent - 移动组件实例
func get_movement() -> PlayerMovementComponent:
	return _player.movement_component

# ========================== 辅助方法模块 ==========================
## 功能：辅助方法，根据输入动作名称切换到对应的技能状态
## 参数：action_name (String) - 输入动作名称（如 "skill_1"、"skill_2"）
## 说明：从玩家获取对应的技能数据，注入到技能状态后切换状态
func _transition_to_skill(action_name: String) -> void:
	var data = _player.get_skill_data_by_action(action_name)
	var skill_state = state_machine.get_state("skill") as PlayerSkillState
	skill_state.setup_skill(data)
	state_machine.change_to("skill")

# ==============================================================================
#   FSMState.gd
#   功能：有限状态机（FSM）的状态基类，提供所有状态共用的生命周期钩子函数
#        （进入/退出、每帧更新、物理更新、输入处理），以及状态机引用和激活标记。
# ==============================================================================
extends Node
class_name FSMState

# ========================== 变量定义模块 ==========================
## 所属状态机的引用（由状态机在注册时注入）
var state_machine: StateMachine

## 当前状态是否处于激活状态（enter 后为 true，exit 后为 false）
var _is_active: bool = false

# ========================== 生命周期钩子模块 ==========================
## 功能：进入状态时调用，执行状态初始化逻辑（如播放动画、重置计时器等）
func enter() -> void:
	_is_active = true

## 功能：退出状态时调用，执行状态清理逻辑（如停止动画、重置标记等）
func exit() -> void:
	_is_active = false

## 功能：判断该状态是否允许实体移动
## 返回值：bool - true 表示允许移动，false 表示禁止移动（用于移动组件过滤）
## 说明：子类可根据需要重写（如受击/攻击状态返回 false）
func is_movement_allowed() -> bool:
	return true

## 功能：每帧更新，在 _process 中调用
## 参数：_delta (float) - 帧间隔时间（秒）
## 说明：子类可重写以执行帧更新逻辑（如冷却倒计时、距离检测等）
func update(_delta: float) -> void:
	pass

## 功能：物理帧更新，在 _physics_process 中调用
## 参数：_delta (float) - 物理帧间隔时间（秒）
## 说明：子类可重写以执行移动、碰撞检测等物理相关逻辑
func physics_update(_delta: float) -> void:
	pass

## 功能：处理输入事件（可选）
## 参数：_event (InputEvent) - 输入事件对象
## 说明：子类可重写以响应特定输入（如攻击状态中忽略跳跃输入）
func handle_input(_event: InputEvent) -> void:
	pass

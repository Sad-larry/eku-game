# ==============================================================================
#   player_input_handler.gd
#   功能：玩家输入处理器，从 InputManager 接收输入信号并转发给 Player。
#        从 player.gd 拆出的独立组件，使输入处理职责单一化。
# ==============================================================================
extends Node
class_name PlayerInputHandler

# ========================== 信号声明模块 ==========================
## 输入动作触发时发射（如 "attack"、"skill_1"）
signal input_action(action: String)
## 移动方向变化时发射
signal movement_dir_changed(dir: Vector2)

# ========================== 生命周期模块 ==========================
## 功能：连接 InputManager 的输入信号
## 说明：连接动作触发和移动方向两个输入信号，转发给 Player 的状态机处理。
##       输入锁定由 InputManager（全局输入屏蔽）和 Player（局部输入屏蔽）双层管理，
##       本组件仅做透传转发，不参与输入锁定判断。
func _ready() -> void:
	InputManager.action_triggered.connect(_on_action)
	InputManager.movement_vector_changed.connect(_on_movement)

# ========================== 信号回调模块 ==========================
## 功能：将 InputManager 的动作信号转发给 Player
## 参数：action (String) - 输入动作名称（如 "attack"、"skill_1"）
func _on_action(action: String) -> void:
	input_action.emit(action)

## 功能：将 InputManager 的移动方向信号转发给 Player
## 参数：dir (Vector2) - 当前移动方向（单位向量）
func _on_movement(dir: Vector2) -> void:
	movement_dir_changed.emit(dir)

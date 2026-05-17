# ==============================================================================
#   player_input_handler.gd
#   功能：玩家输入处理器，从 InputManager 接收输入信号并转发给 Player。
#        持续施法轮询：检测按住技能键并自动重复发射 input_action。
#        从 player.gd 拆出的独立组件，使输入处理职责单一化。
# ==============================================================================
extends Node
class_name PlayerInputHandler

# ========================== 常量定义模块 ==========================
## 按住技能键的最小施法间隔（秒），防止每帧创建多个 fx 实例
const HELD_SKILL_INTERVAL: float = 0.15

# ========================== 信号声明模块 ==========================
## 输入动作触发时发射（如 "attack"、"skill_1"）
signal input_action(action: String)
## 移动方向变化时发射
signal movement_dir_changed(dir: Vector2)

# ========================== 变量定义模块 ==========================
## 持续施法节流计时器
var _held_skill_timer: float = 0.0

# ========================== 生命周期模块 ==========================
## 功能：连接 InputManager 和 EventBus 的输入信号
func _ready() -> void:
	InputManager.action_triggered.connect(_on_action)
	InputManager.movement_vector_changed.connect(_on_movement)
	EventBus.skill_slot_clicked.connect(_on_skill_slot_clicked)

## 功能：每帧检测按住技能键并发射 input_action
## 说明：InputManager.action_triggered 只响应"按下"瞬间，不响应"按住"。
##       此处轮询 InputManager.is_action_pressed() 检测持续按住。
##       HELD_SKILL_INTERVAL 节流防止连续创建多个 fx 实例。
##       输入被阻塞时 is_action_pressed 内部会返回 false。
## 参数：delta (float) - 帧间隔时间（秒）
func _process(delta: float) -> void:
	_held_skill_timer -= delta
	if _held_skill_timer > 0.0:
		return
	for action in ["skill_1", "skill_2", "skill_3", "skill_4"]:
		if InputManager.is_action_pressed(action):
			input_action.emit(action)
			_held_skill_timer = HELD_SKILL_INTERVAL
			return

# ========================== 信号回调模块 ==========================
## 功能：将 InputManager 的动作信号转发给 Player
## 参数：action (String) - 输入动作名称（如 "attack"、"skill_1"）
func _on_action(action: String) -> void:
	input_action.emit(action)

## 功能：将 InputManager 的移动方向信号转发给 Player
## 参数：dir (Vector2) - 当前移动方向（单位向量）
func _on_movement(dir: Vector2) -> void:
	movement_dir_changed.emit(dir)

## 功能：技能槽鼠标点击回调，转为标准 input_action 信号
## 参数：slot_index (int) - 技能槽索引（0~3）
func _on_skill_slot_clicked(slot_index: int) -> void:
	var action := "skill_%d" % [slot_index + 1]
	if not InputManager.is_action_blocked(action):
		input_action.emit(action)

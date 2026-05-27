# ==============================================================================
#   mouse_swipe_detector.gd
#   功能：鼠标滑动检测器，检测左键拖拽手势用于房间轴切换。
#        通过事件消费机制区分"点击"（攻击）和"拖拽"（滑动）：
#        - 鼠标按下时记录起始位置，不消费事件（让 InputManager 正常响应）
#        - 拖拽超过阈值后，消费后续事件（阻止 InputManager 触发攻击动作）
#        - 提供静态 is_dragging 标志供攻击系统查询，防止拖拽期间误触攻击
#   使用方式：作为 Player 节点的子节点添加到场景树中，
#            连接 swipe_detected 信号到 RoomNavigationManager.switch_axis()
# ==============================================================================
extends Node
class_name MouseSwipeDetector

# ========================== 信号声明模块 ==========================
## 触发时机：检测到有效水平滑动时
## 参数：direction (int) - +1 = 左→右（向右滑动），-1 = 右→左（向左滑动）
signal swipe_detected(direction: int)

# ========================== 常量定义模块 ==========================
## 水平滑动最小距离（像素），低于此距离视为点击
const SWIPE_THRESHOLD: float = 100.0
## 垂直滑动最大容忍距离（像素），超过则判定为非水平滑动
const MAX_VERTICAL: float = 50.0

# ========================== 静态状态模块 ==========================
## 当前是否有拖拽手势正在进行（供攻击系统查询）
## 攻击系统在处理 attack 动作前应检查此标志，若为 true 则忽略攻击。
static var is_dragging: bool = false

# ========================== 内部状态模块 ==========================
## 拖拽起始位置（鼠标按下时记录）
var _drag_start: Vector2 = Vector2.ZERO
## 鼠标左键是否处于按下状态
var _button_down: bool = false

# ========================== 输入处理模块 ==========================
## 功能：在 _input 阶段处理鼠标左键事件，区分点击与拖拽。
## 说明：Godot 事件处理顺序为 _input → _unhandled_input。
##       当拖拽超过阈值时，调用 get_viewport().set_input_as_handled() 消费事件，
##       阻止 InputManager._unhandled_input 中的攻击检测被触发。
##       点击（未超阈值）不消费事件，攻击正常触发。
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 鼠标按下：记录起始位置，标记按钮按下
				_drag_start = event.position
				_button_down = true
				is_dragging = false
			else:
				# 鼠标释放：如果正在拖拽则消费事件（阻止攻击触发）
				if _button_down and is_dragging:
					get_viewport().set_input_as_handled()
				# 重置状态
				is_dragging = false
				_button_down = false

	elif event is InputEventMouseMotion:
		if _button_down and not is_dragging:
			# 按钮已按下但尚未确认拖拽：检查是否超过阈值
			var delta :Vector2 = event.position - _drag_start
			if abs(delta.x) >= SWIPE_THRESHOLD and abs(delta.y) <= MAX_VERTICAL:
				# 超过阈值：确认为拖拽，发射滑动信号，消费当前事件
				is_dragging = true
				var direction: int = 1 if delta.x > 0 else -1
				swipe_detected.emit(direction)
				get_viewport().set_input_as_handled()
		elif is_dragging:
			# 拖拽进行中：消费所有移动事件
			get_viewport().set_input_as_handled()

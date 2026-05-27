# ==============================================================================
#   side_scroll_camera.gd
#   功能：2D 横版摄像机控制器，自动跟随 Global.player 玩家对象移动，
#        支持鼠标滚轮缩放和房间边界限制。
# ==============================================================================
extends Camera2D
class_name SideScrollCamera

# ========================== 常量定义模块 ==========================
## 跟随速度，值越大越快
const FOLLOW_SPEED: float = 32.0

# ========================== 导出变量模块 ==========================
## 最小缩放倍数（值越大画面越远，最小不能 <=0）
@export var min_zoom: float = 0.5
## 最大缩放倍数（值越小画面越近）
@export var max_zoom: float = 3.0
## 缩放灵敏度（滚轮每滚动一格，缩放变化倍数因子）
@export var zoom_speed: float = 0.1

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	rotation_degrees = 0
	position_smoothing_enabled = true
	add_to_group("side_scroll_camera")

func _process(delta: float) -> void:
	if is_instance_valid(Global.player):
		global_position = lerp(global_position, Global.player.global_position, 1.0 - exp(-FOLLOW_SPEED * delta))

# ========================== 输入处理模块 ==========================
func _input(event: InputEvent) -> void:
	if InputManager.input_locked:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_mouse(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_mouse(1)

# ========================== 内部缩放逻辑 ==========================
func _zoom_at_mouse(direction: int) -> void:
	zoom *= (1.0 - direction * zoom_speed)
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)

# ========================== 公共 API ==========================
## 功能：设置摄像机边界限制（防止看到房间外）
## 参数：left/top/right/bottom - 边界坐标值
func set_bounds(left: float, top: float, right: float, bottom: float) -> void:
	limit_left = int(left)
	limit_top = int(top)
	limit_right = int(right)
	limit_bottom = int(bottom)

## 功能：清除边界限制
func clear_bounds() -> void:
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000

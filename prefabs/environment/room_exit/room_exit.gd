# ==============================================================================
#   room_exit.gd
#   功能：房间出口脚本，Area2D 子类。
#        检测玩家进入出口区域，通知 RoomNavigationManager 执行房间切换。
#        显示目标房间的 ring 值和难度标签。
# ==============================================================================
extends Area2D
class_name RoomExit

# ========================== 导出变量模块 ==========================
## 出口方向："left" 或 "right"
@export var exit_side: String = "left"

# ========================== 变量定义模块 ==========================
## 目标房间坐标
var target_coord: Vector2i = Vector2i.ZERO
## 是否被阻挡（如 max_ring 边界）
var blocked: bool = false

# ========================== 节点引用模块 ==========================
@onready var label: Label = $Label

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	body_entered.connect(_on_body_entered)

# ========================== 公共 API 模块 ==========================
## 功能：设置出口信息
## 参数：coord (Vector2i) - 目标房间坐标；ring (int) - 目标房间环数
func setup(coord: Vector2i, ring: int) -> void:
	target_coord = coord
	# 检查是否超过 max_ring 边界
	blocked = not RoomNavigationManager.can_enter_room(coord)
	_update_label(ring)

## 功能：更新出口显示
## 参数：ring (int) - 目标房间环数
func _update_label(ring: int) -> void:
	if label == null:
		return
	if blocked:
		label.text = "X"
		label.modulate = Color.RED
	else:
		label.text = "D%d" % ring
		# 颜色映射
		if ring <= 1:
			label.modulate = Color.GREEN
		elif ring <= 3:
			label.modulate = Color.YELLOW
		else:
			label.modulate = Color.RED

# ========================== 信号回调模块 ==========================
func _on_body_entered(body: Node2D) -> void:
	if blocked:
		return
	if body.is_in_group("player"):
		RoomNavigationManager.enter_room(target_coord)

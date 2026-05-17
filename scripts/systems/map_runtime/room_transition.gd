# ==============================================================================
#   room_transition.gd
#   功能：出口 Area2D——玩家走进来触发房间切换
#         负责显示目标房间的难度等级，并在玩家进入时触发 MapManager 的房间切换
# ==============================================================================
extends Area2D
class_name RoomTransition

# ========================== 变量定义模块 ==========================
## 目标房间的网格坐标
var target_coord: Vector2i

## 是否被阻挡（暂不可用）
var blocked: bool = false

# ========================== 节点引用模块 ==========================
## 难度标签节点（用于显示圈层数字）
@onready var label: Label = $DifficultyLabel

## 碰撞形状节点
@onready var collision: CollisionShape2D = $CollisionShape2D

# ========================== 公共 API 模块 ==========================
## 功能：设置出口的目标房间坐标
## 参数：coord (Vector2i) - 目标房间的网格坐标
func set_target(coord: Vector2i) -> void:
	target_coord = coord

## 功能：根据圈层显示难度标签的颜色和文字
## 参数：ring (int) - 目标房间的圈层索引
## 显示规则：0-1 圈为绿色，2-3 圈为黄色，4 圈及以上为红色
func show_difficulty(ring: int) -> void:
	if label == null:
		return

	label.text = "D%d" % ring

	match ring:
		0, 1:
			label.modulate = Color.GREEN
		2, 3:
			label.modulate = Color.YELLOW
		_:
			label.modulate = Color.RED

# ========================== 生命周期模块 ==========================
## 功能：节点进入场景树时调用，连接身体进入信号
func _ready() -> void:
	body_entered.connect(_on_body_entered)

# ========================== 信号处理模块 ==========================
## 功能：当有身体进入出口区域时调用
## 参数：body (Node2D) - 进入区域的节点
## 说明：若 body 为玩家且出口未被阻挡，则触发地图管理器进入目标房间
func _on_body_entered(body: Node2D) -> void:
	# TODO: blocked 检查当前恒为 true，需确认是否为调试状态
	if blocked or true:
		return

	# 判断进入者是否为玩家
	if body.is_in_group("player") or body.has_method("is_player"):
		var map_manager := _find_map_manager()
		if map_manager != null:
			map_manager.enter_room(target_coord)

# ========================== 私有方法模块 ==========================
## 功能：向上查找 MapManager 实例
## 返回值：MapManager - 找到的地图管理器实例，未找到返回 null
func _find_map_manager() -> MapManager:
	var parent := get_parent()
	while parent != null:
		if parent is MapManager:
			return parent
		parent = parent.get_parent()
	return null

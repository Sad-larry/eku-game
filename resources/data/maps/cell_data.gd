# ==============================================================================
#   CellData.gd
#   功能：菱形网格中一个单元格的运行时数据
#         存储坐标、圈层、事件类型、访问状态及难度配置
# ==============================================================================

class_name CellData
extends Resource

# ========================== 导出变量 ==========================

## 网格坐标（格式：{"x": int, "y": int}）
@export var coord: Dictionary

## 所在圈层（曼哈顿距离 abs(x) + abs(y)）
@export var ring: int

## 事件类型标识
## 可选值："start" / "battle" / "elite" / "boss" / "merchant" / "treasure" / "rest"
@export var event_type: String

## 是否已被玩家访问过
@export var is_visited: bool = false

## 是否已完成清理（敌人全清）
@export var is_cleared: bool = false

## 该格子的难度微调系数（影响生成敌人的强度）
@export var difficulty_modifier: float = 1.0

# ========================== 公共方法 ==========================

## 功能：以 Vector2i 形式返回坐标（便利方法）
## 返回值：Vector2i - 坐标的向量形式
func get_coord_vec() -> Vector2i:
	return Vector2i(coord["x"], coord["y"])

## 功能：判断是否为战斗类事件（会生成敌人）
## 返回值：bool - 是否为战斗事件（battle/elite/boss）
func is_combat_event() -> bool:
	return event_type in ["battle", "elite", "boss"]

## 功能：判断是否为安全类事件（无敌人）
## 返回值：bool - 是否为安全事件（start/merchant/treasure/rest）
func is_safe_event() -> bool:
	return event_type in ["start", "merchant", "treasure", "rest"]

## 功能：返回单元格数据的可读字符串表示
## 返回值：String - 格式化的调试信息
func _to_string() -> String:
	# 安全获取坐标值，避免键缺失
	var x = coord.get("x", 0)
	var y = coord.get("y", 0)
	
	# 拼接清晰格式
	return "CellData(坐标=(%d,%d), 圈层=%d, 事件=%s, 访问=%s, 清理=%s, 难度系数=%.1f)" % [
		x, y,
		ring,
		event_type if event_type != "" else "(空)",
		str(is_visited),
		str(is_cleared),
		difficulty_modifier
	]

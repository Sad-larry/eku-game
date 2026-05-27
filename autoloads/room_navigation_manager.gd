# ==============================================================================
#   room_navigation_manager.gd
#   功能：房间导航管理器（Autoload 单例）。
#        管理 2D 网格坐标、轴切换状态、出口计算、max_ring 边界检查。
#        实现"鼠标滑动旋转房间轴"的核心导航逻辑。
# ==============================================================================
extends Node

# ========================== 信号声明模块 ==========================
## 触发时机：轴切换时
## 参数：new_axis (String) - 新的活跃轴（"x" 或 "y"）
signal axis_changed(new_axis: String)

## 触发时机：请求房间切换时
## 参数：target_coord (Vector2i) - 目标房间坐标
signal room_transition_requested(target_coord: Vector2i)

# ========================== 变量定义模块 ==========================
## 当前房间坐标
var current_coord: Vector2i = Vector2i.ZERO
## 当前活跃轴："x" 或 "y"
var active_axis: String = "x"
## Y 轴方向映射（+1 或 -1），控制左右走对应 y 正方向还是负方向
var _y_direction: int = 1
## 最大环数限制（曼哈顿距离）
var max_ring: int = 4
## 地图数据引用
var _map_data: RefCounted = null

# ========================== 公共 API 模块 ==========================
## 功能：初始化导航管理器
## 参数：map_data - RadialGridMap 地图数据；ring_limit - 最大环数
func setup(map_data: RefCounted, ring_limit: int) -> void:
	_map_data = map_data
	max_ring = ring_limit
	current_coord = Vector2i.ZERO
	active_axis = "x"
	_y_direction = 1

## 功能：根据当前轴状态，计算左右出口的目标坐标
## 返回值：Dictionary - {"left": Vector2i, "right": Vector2i}
func get_exit_coords() -> Dictionary:
	var left_coord: Vector2i
	var right_coord: Vector2i

	if active_axis == "x":
		left_coord = current_coord + Vector2i(-1, 0)
		right_coord = current_coord + Vector2i(1, 0)
	else:
		# Y 轴模式：左右走改变 y 值，方向由 _y_direction 决定
		left_coord = current_coord + Vector2i(0, -_y_direction)
		right_coord = current_coord + Vector2i(0, _y_direction)

	return {"left": left_coord, "right": right_coord}

## 功能：切换活跃轴
## 参数：direction (int) - 滑动方向，+1 = 左→右，-1 = 右→左
func switch_axis(direction: int) -> void:
	if active_axis == "x":
		active_axis = "y"
		_y_direction = direction
	else:
		# 已在 Y 轴模式时，根据滑动方向翻转 y 方向
		if direction != _y_direction:
			_y_direction = direction
		else:
			# 同方向滑动，切回 X 轴
			active_axis = "x"
			_y_direction = 1

	axis_changed.emit(active_axis)

## 功能：检查目标坐标是否可进入（不超过 max_ring）
## 参数：coord (Vector2i) - 目标房间坐标
## 返回值：bool - true 表示可以进入
func can_enter_room(coord: Vector2i) -> bool:
	var ring :int = abs(coord.x) + abs(coord.y)
	return ring <= max_ring

## 功能：执行房间切换
## 参数：coord (Vector2i) - 目标房间坐标
func enter_room(coord: Vector2i) -> void:
	if not can_enter_room(coord):
		return
	current_coord = coord
	room_transition_requested.emit(coord)

## 功能：获取当前房间的 ring 值
## 返回值：int - 曼哈顿距离
func get_current_ring() -> int:
	return abs(current_coord.x) + abs(current_coord.y)

## 功能：获取指定坐标的 ring 值
## 参数：coord (Vector2i) - 房间坐标
## 返回值：int - 曼哈顿距离
func get_ring_at(coord: Vector2i) -> int:
	return abs(coord.x) + abs(coord.y)

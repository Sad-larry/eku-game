# ==============================================================================
#   room_manager.gd
#   功能：房间运行时状态管理器（Autoload 单例）。
#        追踪玩家当前所在的房间坐标，维护每个房间的运行时状态。
#        直接操作网格坐标（与 RadialGridMap 坐标系一致），不依赖 RoomBase。
# ==============================================================================
extends Node

# ========================== 枚举定义模块 ==========================
## 房间运行时状态枚举
enum RoomState {
	UNVISITED,  # 从未进入
	ACTIVE,     # 玩家当前在此房间中
	CLEARED,    # 事件已解决（战斗清场/已购买/已开启）
}

# ========================== 信号声明模块 ==========================
## 触发时机：玩家进入新房间时
## 参数：coord (Vector2i) - 房间坐标；ring (int) - 房间所在环数；event_type (String) - 事件类型
signal room_entered(coord: Vector2i, ring: int, event_type: String)

## 触发时机：房间被清除时（战斗胜利/事件完成）
## 参数：coord (Vector2i) - 房间坐标
signal room_cleared(coord: Vector2i)

## 触发时机：房间状态发生变化时
## 参数：coord (Vector2i) - 房间坐标；new_state (int) - 新状态（RoomState 枚举值）
signal room_state_changed(coord: Vector2i, new_state: int)

# ========================== 变量定义模块 ==========================
## 房间状态字典：key="x,y" → RoomState
var _room_states: Dictionary = {}
## 当前房间坐标（用于检查点保存）
var current_coord: Vector2i = Vector2i.ZERO

# ========================== 公共 API 模块 ==========================
## 功能：通知 RoomManager 玩家进入了指定房间
## 参数：coord (Vector2i) - 目标房间坐标；ring (int) - 房间所在环数；event_type (String) - 事件类型
## 返回值：bool - true 表示成功切换，false 表示已在同一房间
func enter_room(coord: Vector2i, ring: int, event_type: String) -> bool:
	if coord == current_coord:
		return false

	current_coord = coord

	# 首次进入则记录状态
	var key := _key(coord)
	if not _room_states.has(key):
		_room_states[key] = RoomState.ACTIVE
		room_state_changed.emit(coord, RoomState.ACTIVE)

	room_entered.emit(coord, ring, event_type)
	return true

## 功能：查询指定房间的运行时状态
## 参数：coord (Vector2i) - 房间坐标
## 返回值：int - 房间状态（RoomState 枚举值），未访问返回 UNVISITED
func get_state(coord: Vector2i) -> int:
	return _room_states.get(_key(coord), RoomState.UNVISITED)

## 功能：强制设置指定房间的状态
## 参数：coord (Vector2i) - 房间坐标；state (int) - 目标状态（RoomState 枚举值）
func set_state(coord: Vector2i, state: int) -> void:
	_room_states[_key(coord)] = state
	room_state_changed.emit(coord, state)
	if state == RoomState.CLEARED:
		room_cleared.emit(coord)

## 功能：快捷查询房间是否已清除
## 参数：coord (Vector2i) - 房间坐标
## 返回值：bool - true 表示房间已清除
func is_cleared(coord: Vector2i) -> bool:
	return _room_states.get(_key(coord), RoomState.UNVISITED) == RoomState.CLEARED

## 功能：重置所有状态（新冒险开始时调用）
func reset_all() -> void:
	_room_states.clear()
	current_coord = Vector2i.ZERO

# ========================== 工具方法模块 ==========================
## 功能：将房间坐标转换为字典键
## 参数：coord (Vector2i) - 房间坐标
## 返回值：String - 格式为 "x,y" 的键字符串
static func _key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

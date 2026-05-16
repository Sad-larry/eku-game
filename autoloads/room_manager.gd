# ==============================================================================
#   room_manager.gd
#   功能：格子运行时状态管理器（Autoload 单例）。
#         追踪玩家当前所在的菱形网格格子，维护每个格子的运行时状态。
#         不依赖 RoomBase，直接操作网格坐标（与 RadialGridMap 坐标系一致）。
# ==============================================================================
extends Node

# ========================== 格子状态枚举 ==========================
enum RoomState {
	UNVISITED,  # 从未进入
	ACTIVE,     # 玩家当前在此格子中
	CLEARED,    # 事件已解决（战斗清场/已购买/已开启）
}

# ========================== 运行时状态 ==========================
## 格子状态字典：key="x,y" → RoomState
var _room_states: Dictionary = {}

## 当前格子坐标
var current_coord: Vector2i = Vector2i.ZERO

## 当前格子的 ring 值
var current_ring: int = 0

## 当前格子的事件类型
var current_event_type: String = ""

# ========================== 信号 ==========================
## 玩家进入新格子时触发
signal room_entered(coord: Vector2i, ring: int, event_type: String)

## 格子被清除时触发
signal room_cleared(coord: Vector2i)

## 格子状态变化时触发
signal room_state_changed(coord: Vector2i, new_state: int)

# ========================== 公共 API ==========================
## 通知 RoomManager 玩家进入了指定格子
## 返回值：true=成功切换，false=已在同一格子
func enter_room(coord: Vector2i, ring: int, event_type: String) -> bool:
	if coord == current_coord:
		return false

	# 更新当前格子（不清除上一个格子，由战斗系统通过 set_state 显式触发）
	current_coord = coord
	current_ring = ring
	current_event_type = event_type

	# 首次进入则初始化为 ACTIVE
	var key := _key(coord)
	if not _room_states.has(key):
		_room_states[key] = RoomState.ACTIVE
		room_state_changed.emit(coord, RoomState.ACTIVE)

	room_entered.emit(coord, ring, event_type)
	return true

## 查询格子的运行时状态
func get_state(coord: Vector2i) -> int:
	return _room_states.get(_key(coord), RoomState.UNVISITED)

## 强制设置格子状态
func set_state(coord: Vector2i, state: int) -> void:
	_room_states[_key(coord)] = state
	room_state_changed.emit(coord, state)
	if state == RoomState.CLEARED:
		room_cleared.emit(coord)

## 快捷查询格子是否已清除
func is_cleared(coord: Vector2i) -> bool:
	return _room_states.get(_key(coord), RoomState.UNVISITED) == RoomState.CLEARED

## 重置所有状态（新冒险开始时调用）
func reset_all() -> void:
	_room_states.clear()
	current_coord = Vector2i.ZERO
	current_ring = 0
	current_event_type = ""

# ========================== 工具 ==========================
static func _key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

# ==============================================================================
#   side_room.gd
#   功能：2D 横版房间模板脚本，Node2D 子类。
#        管理墙壁、出口、事件内容容器、出生点。
#        支持"预览模式"（仅地形+出口）和"激活模式"（含事件内容）。
# ==============================================================================
extends Node2D
class_name SideRoom

# ========================== 信号声明模块 ==========================
## 触发时机：玩家通过出口离开房间时
## 参数：exit_side (String) - "left" 或 "right"
signal player_exited(exit_side: String)

# ========================== 节点引用模块 ==========================
@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var walls: Node2D = $Walls
@onready var exits: Node2D = $Exits
@onready var event_content: Node2D = $EventContent
@onready var spawn_points: Node2D = $SpawnPoints
@onready var player_entry_left: Marker2D = $PlayerEntryLeft
@onready var player_entry_right: Marker2D = $PlayerEntryRight

# ========================== 变量定义模块 ==========================
## 关联的单元格数据
var cell_data: CellData
## 房间难度等级
var difficulty: int
## 房间坐标
var coord: Vector2i
## 是否已激活（生成事件内容）
var is_active: bool = false
## 是否为预览模式（仅地形+出口，无事件内容）
var is_preview: bool = true

# ========================== 公共 API 模块 ==========================
## 功能：设置房间基础数据
## 参数：data (CellData) - 单元格数据
func setup(data: CellData) -> void:
	cell_data = data
	difficulty = data.ring
	coord = data.get_coord_vec()

## 功能：设置房间出口
## 参数：exit_coords (Dictionary) - {"left": Vector2i, "right": Vector2i}
##       map_data (RadialGridMap) - 地图数据引用
func setup_exits(exit_coords: Dictionary, map_data: RefCounted) -> void:
	var left_exit := exits.get_node_or_null("LeftExit") as RoomExit
	var right_exit := exits.get_node_or_null("RightExit") as RoomExit

	if left_exit and exit_coords.has("left"):
		var left_coord: Vector2i = exit_coords["left"]
		var left_cell: CellData = map_data.get_cell(left_coord.x, left_coord.y)
		if left_cell:
			left_exit.setup(left_coord, left_cell.ring)
			left_exit.show()
		else:
			left_exit.hide()
	elif left_exit:
		left_exit.hide()

	if right_exit and exit_coords.has("right"):
		var right_coord: Vector2i = exit_coords["right"]
		var right_cell: CellData = map_data.get_cell(right_coord.x, right_coord.y)
		if right_cell:
			right_exit.setup(right_coord, right_cell.ring)
			right_exit.show()
		else:
			right_exit.hide()
	elif right_exit:
		right_exit.hide()

## 功能：激活房间（生成事件内容）
## 说明：从预览模式切换到激活模式
func activate() -> void:
	if is_active:
		return
	is_active = true
	is_preview = false
	# 事件内容由 GameWorld 的 RoomContentGenerator 生成
	# 此处只标记激活状态

## 功能：设置为预览模式（仅地形+出口）
func set_preview() -> void:
	is_preview = true
	is_active = false
	# 隐藏事件内容
	if event_content:
		event_content.visible = false

## 功能：获取玩家从指定方向进入时的位置
## 参数：from_side (String) - "left" 或 "right"
## 返回值：Vector2 - 世界坐标
func get_player_entry_position(from_side: String) -> Vector2:
	if from_side == "left":
		return player_entry_left.global_position if player_entry_left else global_position
	else:
		return player_entry_right.global_position if player_entry_right else global_position

## 功能：获取初始出生点（仅 (0,0) 房间使用）
## 返回值：Vector2 - 世界坐标
func get_spawn_position() -> Vector2:
	var spawn := get_node_or_null("PlayerSpawn") as Marker2D
	return spawn.global_position if spawn else global_position

## 功能：获取敌人出生点列表
## 返回值：Array[Vector2] - 所有出生点的世界坐标
func get_enemy_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for child in spawn_points.get_children():
		if child is Marker2D:
			positions.append(child.global_position)
	return positions

## 功能：设置房间边界（供摄像机限制使用）
## 返回值：Rect2 - 房间的世界坐标边界
func get_bounds() -> Rect2:
	# 默认房间大小，可由 TileMapLayer 的 used_rect 计算
	var rect := Rect2(global_position - Vector2(320, 180), Vector2(640, 360))
	return rect

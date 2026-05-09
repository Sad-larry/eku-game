# ==============================================================================
#   ChunkRoom.gd
#   功能：一个网格单元格对应的房间实例——管理出口状态和事件内容
#         负责设置房间的基础数据、出口连接、瓦片地形以及出口阻挡逻辑
# ==============================================================================

class_name ChunkRoom
extends Node2D

# ========================== 节点引用 ==========================

## 房间内的 TileMap 图层节点（用于显示地形瓦片）
@onready var tile_map: TileMapLayer = %TileMapLayer

## 事件内容容器节点（用于存放敌人、商人、宝箱等动态内容）
@onready var event_container: Node2D = %EventContent

## 房间出口容器节点（包含四个方向出口的 Area2D）
@onready var transitions_node: Node2D = %RoomTransitions

# ========================== 成员变量 ==========================

## 关联的单元格数据（包含坐标、圈层、事件类型、访问状态等）
var cell_data: CellData

## 房间难度等级（即所在的圈层索引）
var difficulty: int

# ========================== 公共方法 ==========================

## 功能：设置房间的基础数据
## 参数：data - 单元格数据，包含圈层、事件类型等信息
func setup(data: CellData) -> void:
	cell_data = data
	difficulty = data.ring

## 功能：设置房间的四个方向出口
## 参数：exit_map - 方向到目标格子数据的映射字典
##       键为方向字符串（"north"/"south"/"east"/"west"），值为相邻的 CellData
func setup_exits(exit_map: Dictionary) -> void:
	# 遍历四个方向
	for direction in ["north", "south", "east", "west"]:
		# 构造出口节点名称（如 "Exit_North"）
		var exit_path := "Exit_%s" % direction.capitalize()
		var exit_point := transitions_node.get_node_or_null(exit_path) as RoomTransition
		if exit_point == null:
			continue
		
		var target: CellData = exit_map.get(direction, null)
		if target != null:
			# 有相邻房间：显示出口并设置目标坐标和难度
			exit_point.show()
			exit_point.set_target(target.get_coord_vec())
			exit_point.show_difficulty(target.ring)
			exit_point.blocked = _is_exit_blocked(target)
		else:
			# 无相邻房间：隐藏出口
			exit_point.hide()

## 功能：设置房间瓦片数据（由 ChunkLoader 调用）
## 参数：layer_data - 包含瓦片集、位置和单元格数据的 TileMapLayer 实例
func apply_tile_data(layer_data: TileMapLayer) -> void:
	# 复制瓦片集配置
	tile_map.tile_set = layer_data.tile_set
	tile_map.position = layer_data.position
	
	# 复制所有单元格数据
	for cell_pos in layer_data.get_used_cells():
		var atlas := layer_data.get_cell_atlas_coords(cell_pos)
		var source := layer_data.get_cell_source_id(cell_pos)
		tile_map.set_cell(cell_pos, source, atlas)

# ========================== 私有方法 ==========================

## 功能：判断出口是否被阻挡
## 参数：cell - 目标单元格数据
## 返回值：bool - 如果目标为 BOSS 房间且未被访问过则返回 true，否则返回 false
func _is_exit_blocked(cell: CellData) -> bool:
	# BOSS 房间在未访问时阻挡入口，防止玩家绕过 BOSS
	return cell.event_type == "boss" and not cell.is_visited

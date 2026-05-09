# ==============================================================================
#   MapManager.gd
#   功能：管理整个菱形地图的生命周期——生成、切换、状态追踪
#         负责地图生成、房间切换、出口获取、当前房间管理等核心逻辑
# ==============================================================================

class_name MapManager
extends Node

# ========================== 信号声明 ==========================

## 触发时机：即将进入房间时，在卸载当前房间之前
## 参数：coord - 目标房间坐标，cell_data - 目标房间的格子数据
signal room_entering(coord: Vector2i, cell_data: CellData)

## 触发时机：已进入房间，房间实例化并设置完成后
## 参数：coord - 已进入的房间坐标，room - 房间实例
signal room_entered(coord: Vector2i, room: ChunkRoom)

# TODO 地图生成时才会显示场景，可以添加动画等等
#signal map_completed

# ========================== 导出变量 ==========================

## 菱形地图配置资源
@export var map_config: RadialGridConfig

## 区块房间场景预制体
@export var chunk_room_scene: PackedScene

# ========================== 成员变量 ==========================

## 生成后的完整地图数据
var map_data: RadialGridMap

## 当前所在房间的坐标
var current_coord: Vector2i

## 当前所在的房间实例
var current_room: ChunkRoom

## 区块加载器引用
var _chunk_loader: ChunkLoader

## 房间事件生成器引用
var _event_spawner: RoomEventSpawner

# ========================== 生命周期 ==========================

## 功能：节点进入场景树时调用
## 获取子节点引用并校验关键依赖
func _ready() -> void:
	_chunk_loader = $ChunkLoader as ChunkLoader
	_event_spawner = $RoomEventSpawner as RoomEventSpawner
	
	if _chunk_loader == null:
		push_error("MapManager: 未找到 ChunkLoader 子节点")

# ========================== 公共方法 ==========================

## 功能：生成完整的地图数据
## 使用 RadialGridGenerator 根据配置生成地图，并传递给区块加载器
func generate_map() -> void:
	var generator := RadialGridGenerator.new()
	map_data = generator.generate(map_config)
	
	if _chunk_loader != null:
		_chunk_loader.map_data = map_data

## 功能：进入指定坐标的房间
## 参数：coord - 目标房间的网格坐标
## 处理流程：发送进入前信号 → 卸载当前房间 → 标记访问 → 实例化新房间 → 发送进入后信号
func enter_room(coord: Vector2i) -> void:
	# 获取目标房间的格子数据
	var cell := map_data.get_cell(coord.x, coord.y)
	if cell == null:
		return
	
	# 发送进入前信号
	room_entering.emit(coord, cell)
	
	# 卸载当前房间
	_unload_current_room()
	
	# 标记房间已访问
	cell.is_visited = true
	
	# 实例化新房间
	var room := _instantiate_room(cell)
	
	# TODO: 以下为预留的扩展功能点
	# _setup_exits(room, cell)
	# _spawn_room_content(room, cell)
	
	# 更新当前状态并发送进入后信号
	current_coord = coord
	current_room = room
	room_entered.emit(coord, room)

## 功能：从起点开始游戏（中心格）
## 进入坐标为 (0, 0) 的房间
func start_from_center() -> void:
	enter_room(Vector2i.ZERO)

## 功能：获取当前房间可用的出口列表
## 返回值：Array[CellData] - 当前房间所有相邻且可访问的格子数据
func get_available_exits() -> Array[CellData]:
	if map_data == null:
		return []
	return map_data.get_accessible_neighbors(current_coord.x, current_coord.y)

# ========================== 私有方法 ==========================

## 功能：卸载当前房间
## 释放房间资源并从场景树中移除
func _unload_current_room() -> void:
	if current_room != null and is_instance_valid(current_room):
		if _chunk_loader != null:
			_chunk_loader.unload_room_chunk(current_coord)
		current_room.queue_free()
		current_room = null

## 功能：实例化一个新的房间
## 参数：cell - 房间对应的格子数据
## 返回值：ChunkRoom - 实例化并初始化后的房间节点
func _instantiate_room(cell: CellData) -> ChunkRoom:
	# 实例化房间场景
	var room := chunk_room_scene.instantiate() as ChunkRoom
	add_child(room)
	
	# 让 ChunkLoader 生成地形瓦片
	if _chunk_loader != null:
		var coord_vec := cell.get_coord_vec()
		_chunk_loader.load_room_chunk(coord_vec, room)
	
	# 设置房间基础数据
	room.setup(cell)
	return room

## 功能：设置房间的出口连接（预留扩展）
## 参数：room - 房间实例，cell - 房间对应的格子数据
func _setup_exits(room: ChunkRoom, cell: CellData) -> void:
	var neighbors := map_data.get_neighbors(cell.coord.x, cell.coord.y)
	var exit_map: Dictionary = {}
	
	for n in neighbors:
		var dx: int = n.coord.x - cell.coord.x
		var dy: int = n.coord.y - cell.coord.y
		var dir := _direction_name(dx, dy)
		exit_map[dir] = n
	
	room.setup_exits(exit_map)

## 功能：生成房间内的内容（事件、敌人等）（预留扩展）
## 参数：room - 房间实例，cell - 房间对应的格子数据
func _spawn_room_content(room: ChunkRoom, cell: CellData) -> void:
	if _event_spawner != null:
		_event_spawner.spawn_for_room(room, cell)

## 功能：根据方向偏移量获取方向名称
## 参数：dx - X 轴偏移量，dy - Y 轴偏移量
## 返回值：String - 方向名称（east/west/south/north），无匹配返回空字符串
static func _direction_name(dx: int, dy: int) -> String:
	if dx == 1: return "east"
	if dx == -1: return "west"
	if dy == 1: return "south"
	if dy == -1: return "north"
	return ""

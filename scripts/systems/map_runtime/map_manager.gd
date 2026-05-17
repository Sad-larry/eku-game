# ==============================================================================
#   map_manager.gd
#   功能：管理整个菱形地图的生命周期——生成、切换、状态追踪
#         负责地图生成、房间切换、出口获取、当前房间管理等核心逻辑
# ==============================================================================
extends Node
class_name MapManager

# ========================== 信号声明模块 ==========================
## 触发时机：即将进入房间时，在卸载当前房间之前
## 参数：coord - 目标房间坐标，cell_data - 目标房间的格子数据
signal room_entering(coord: Vector2i, cell_data: CellData)

## 触发时机：已进入房间，房间实例化并设置完成后
## 参数：coord - 已进入的房间坐标，room - 房间实例
signal room_entered(coord: Vector2i, room: ChunkRoom)

# TODO 地图生成时才会显示场景，可以添加动画等等
#signal map_completed

# ========================== 导出变量模块 ==========================
## 菱形地图配置资源
@export var map_config: RadialGridConfig
## 区块房间场景预制体
@export var chunk_room_scene: PackedScene

# ========================== 成员变量模块 ==========================
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

# ========================== 生命周期模块 ==========================
## 功能：节点进入场景树时调用
## 获取子节点引用并校验关键依赖
func _ready() -> void:
	_chunk_loader = $ChunkLoader as ChunkLoader
	_event_spawner = $RoomEventSpawner as RoomEventSpawner

	if _chunk_loader == null:
		push_error("MapManager: 未找到 ChunkLoader 子节点")

# ========================== 公共方法模块 ==========================
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
func start_from_center() -> void:
	enter_room(Vector2i.ZERO)

# ========================== 内部方法模块 ==========================
## 功能：卸载当前房间
func _unload_current_room() -> void:
	if current_room:
		current_room.queue_free()
		current_room = null

## 功能：实例化指定格子的房间
## 参数：cell - 格子数据
## 返回值：ChunkRoom - 实例化的房间实例
func _instantiate_room(cell: CellData) -> ChunkRoom:
	var room := chunk_room_scene.instantiate() as ChunkRoom
	room.cell_data = cell
	get_tree().current_scene.add_child(room)
	return room

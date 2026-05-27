# ==============================================================================
#   room_loader.gd
#   功能：房间动态加载管理器。
#        进入某房间时预加载上下左右 4 个相邻房间（仅地形+出口），
#        玩家通过出口进入相邻房间时实现无缝衔接，
#        卸载不再相邻的房间。
# ==============================================================================
extends Node
class_name RoomLoader

# ========================== 常量定义模块 ==========================
## 房间场景路径（需要手动创建）
const SIDE_ROOM_SCENE_PATH: String = "res://prefabs/environment/side_room/side_room.tscn"

# ========================== 信号声明模块 ==========================
## 触发时机：房间加载完成时
## 参数：coord (Vector2i) - 房间坐标；room (SideRoom) - 房间实例
signal room_loaded(coord: Vector2i, room: SideRoom)

## 触发时机：房间卸载时
## 参数：coord (Vector2i) - 房间坐标
signal room_unloaded(coord: Vector2i)

## 触发时机：主房间切换时（玩家进入新房间）
## 参数：coord (Vector2i) - 新主房间坐标
signal main_room_changed(coord: Vector2i)

# ========================== 变量定义模块 ==========================
## 地图数据引用
var _map_data: RefCounted = null
## 房间预制体
var _room_scene: PackedScene = null
## 房间容器节点（所有房间实例的父节点）
var _room_container: Node2D = null

## 已加载的房间字典：key = "x,y" -> SideRoom
var _loaded_rooms: Dictionary = {}
## 当前主房间坐标
var _main_room_coord: Vector2i = Vector2i.ZERO
## 预加载的相邻坐标列表
var _adjacent_coords: Array[Vector2i] = []

# ========================== 公共 API 模块 ==========================
## 功能：初始化房间加载器
## 参数：map_data - RadialGridMap 地图数据；container - 房间容器节点
func setup(map_data: RefCounted, container: Node2D) -> void:
	_map_data = map_data
	_room_container = container
	_room_scene = load(SIDE_ROOM_SCENE_PATH) as PackedScene

## 功能：加载起始房间及相邻房间
## 参数：start_coord (Vector2i) - 起始房间坐标
func load_start_room(start_coord: Vector2i) -> void:
	_main_room_coord = start_coord
	# 加载主房间（激活模式）
	_load_room(start_coord, false)
	# 预加载相邻房间（预览模式）
	_load_adjacent_rooms(start_coord)
	# 通知主房间变更
	main_room_changed.emit(start_coord)

## 功能：切换主房间（玩家进入新房间时调用）
## 参数：new_coord (Vector2i) - 新主房间坐标
##       from_side (String) - 玩家从哪个方向进入（"left" 或 "right"）
func transition_to_room(new_coord: Vector2i, from_side: String) -> void:
	# 将旧主房间降级为预览
	if _loaded_rooms.has(_key(_main_room_coord)):
		var old_room: SideRoom = _loaded_rooms[_key(_main_room_coord)]
		old_room.set_preview()

	# 更新主房间坐标
	_main_room_coord = new_coord

	# 激活新主房间
	if _loaded_rooms.has(_key(new_coord)):
		var new_room: SideRoom = _loaded_rooms[_key(new_coord)]
		new_room.activate()
	else:
		# 如果未预加载，立即加载
		_load_room(new_coord, false)

	# 卸载不再相邻的房间
	_unload_distant_rooms()

	# 预加载新主房间的相邻房间
	_load_adjacent_rooms(new_coord)

	# 通知主房间变更
	main_room_changed.emit(new_coord)

## 功能：获取已加载的房间实例
## 参数：coord (Vector2i) - 房间坐标
## 返回值：SideRoom 或 null
func get_room(coord: Vector2i) -> SideRoom:
	return _loaded_rooms.get(_key(coord), null)

## 功能：获取当前主房间
## 返回值：SideRoom 或 null
func get_main_room() -> SideRoom:
	return get_room(_main_room_coord)

## 功能：获取主房间坐标
## 返回值：Vector2i
func get_main_coord() -> Vector2i:
	return _main_room_coord

## 功能：卸载所有房间
func unload_all() -> void:
	for key in _loaded_rooms:
		var room: SideRoom = _loaded_rooms[key]
		if is_instance_valid(room):
			room.queue_free()
	_loaded_rooms.clear()

# ========================== 内部方法 ==========================

## 功能：加载单个房间
## 参数：coord (Vector2i) - 房间坐标；preview (bool) - 是否为预览模式
func _load_room(coord: Vector2i, preview: bool) -> void:
	if _loaded_rooms.has(_key(coord)):
		return

	var cell: CellData = _map_data.get_cell(coord.x, coord.y)
	if cell == null:
		return

	var room: SideRoom = _room_scene.instantiate()
	_room_container.add_child(room)

	# 设置房间数据
	room.setup(cell)

	# 计算房间世界位置（网格布局，每个房间固定大小）
	room.position = _coord_to_world(coord)

	# 设置出口
	var exit_coords := _get_exit_coords_for(coord)
	room.setup_exits(exit_coords, _map_data)

	# 设置模式
	if preview:
		room.set_preview()
	else:
		room.activate()

	# 存储引用
	_loaded_rooms[_key(coord)] = room
	room_loaded.emit(coord, room)

## 功能：预加载指定坐标的相邻房间
## 参数：coord (Vector2i) - 中心坐标
func _load_adjacent_rooms(coord: Vector2i) -> void:
	var neighbors := _get_neighbor_coords(coord)
	for neighbor in neighbors:
		if not _loaded_rooms.has(_key(neighbor)):
			_load_room(neighbor, true)
	_adjacent_coords = neighbors

## 功能：卸载不再相邻的房间
func _unload_distant_rooms() -> void:
	var current_neighbors := _get_neighbor_coords(_main_room_coord)
	# 加入主房间自身
	current_neighbors.append(_main_room_coord)

	var to_remove: Array[String] = []
	for key in _loaded_rooms:
		var parts :String = key.split(",")
		var coord := Vector2i(int(parts[0]), int(parts[1]))
		if coord not in current_neighbors:
			to_remove.append(key)

	for key in to_remove:
		var room: SideRoom = _loaded_rooms[key]
		if is_instance_valid(room):
			room.queue_free()
		_loaded_rooms.erase(key)
		var parts := key.split(",")
		room_unloaded.emit(Vector2i(int(parts[0]), int(parts[1])))

## 功能：获取指定坐标的相邻坐标（上下左右）
## 参数：coord (Vector2i) - 中心坐标
## 返回值：Array[Vector2i] - 有效的相邻坐标列表
func _get_neighbor_coords(coord: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var neighbor :Vector2i = coord + offset
		if _map_data and _map_data.get_cell(neighbor.x, neighbor.y) != null:
			neighbors.append(neighbor)
	return neighbors

## 功能：获取指定坐标的出口目标坐标
## 参数：coord (Vector2i) - 房间坐标
## 返回值：Dictionary - {"left": Vector2i, "right": Vector2i}
func _get_exit_coords_for(coord: Vector2i) -> Dictionary:
	# 使用导航管理器的轴状态计算出口
	# 但需要临时替换 current_coord
	var saved_coord := RoomNavigationManager.current_coord
	RoomNavigationManager.current_coord = coord
	var exits := RoomNavigationManager.get_exit_coords()
	RoomNavigationManager.current_coord = saved_coord
	return exits

## 功能：坐标转世界位置（网格布局）
## 参数：coord (Vector2i) - 房间坐标
## 返回值：Vector2 - 世界位置
func _coord_to_world(coord: Vector2i) -> Vector2:
	# 每个房间 640x360 像素，间隔 0 像素（无缝拼接）
	const ROOM_WIDTH: float = 640.0
	const ROOM_HEIGHT: float = 360.0
	return Vector2(coord.x * ROOM_WIDTH, coord.y * ROOM_HEIGHT)

## 功能：坐标转字典键
static func _key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]

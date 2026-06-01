# ==============================================================================
#   chunk_manager.gd
#   功能：基于区块（Chunk）的动态地图加载系统，监视玩家位置，
#        按需加载/卸载 TileMapLayer 区块，以性能优先。
#   用法：作为 LobbyWorld 的子节点，导出 TileSet 和生成器即可工作。
# ==============================================================================
# [重构注释] 2.5D等距地图相关代码已暂时禁用
extends Node
class_name ChunkManager
#
# # ========================== 信号声明模块 ==========================
# ## 触发时机：某个区块完成加载并加入场景树时
# ## 参数：chunk_x (int) - 区块 X 坐标；chunk_y (int) - 区块 Y 坐标
# signal chunk_loaded(chunk_x: int, chunk_y: int)
#
# ## 触发时机：某个区块被卸载并从场景树移除时
# ## 参数：chunk_x (int) - 区块 X 坐标；chunk_y (int) - 区块 Y 坐标
# signal chunk_unloaded(chunk_x: int, chunk_y: int)
#
# # ========================== 导出配置模块 ==========================
# ## 区块瓦片的 Z 索引，设为 -1 确保始终在实体下方
# @export var chunk_z_index: int = -1
#
# ## 共享的 TileSet 资源（从 Grassland 节点提取的 .tres 文件）
# @export var tileset: TileSet
#
# ## 每个区块包含的瓦片数（宽和高均为该值）
# @export var chunk_size: int = 32
#
# ## 玩家加载区块的半径（以区块数为单位）。半径 2 即加载 (2*2+1)² = 25 个区块
# @export var load_radius: int = 2
#
# ## 卸载区块的半径阈值。超出此半径的区块才会被回收，避免频繁创建/销毁
# @export var unload_radius: int = 3
#
# ## 全局随机种子，确保同一位置每次运行生成一致的地形
# @export var world_seed: int = 42
#
# ## 检测玩家位置的间隔（秒），避免每帧检查
# @export var check_interval: float = 0.25
#
# # ========================== 变量定义模块 ==========================
# ## 瓦片生成器实例（可替换为不同地形的生成器）
# var generator: TerrainGenerator
#
# ## 已加载区块字典：key = "cx,cy"（字符串），value = TileMapLayer 节点
# var _loaded_chunks: Dictionary = {}
#
# ## 玩家上一次所在的区块坐标
# var _last_player_chunk: Vector2i = Vector2i(999999, 999999)
#
# ## 瓦片尺寸（从 TileSet 读取）
# var _tile_size: Vector2i = Vector2i(32, 16)
#
# ## 累计时间计数器（用于间隔检查）
# var _accumulated_time: float = 0.0
#
# ## 对象池引用（可选，若 ChunkPool 子节点存在则自动使用）
# var _pool: ChunkPool = null
#
# ## 参考 TileMapLayer（仅用于坐标转换，不加入场景树）
# var _reference_layer: TileMapLayer = null
#
# ## Ring/事件数据（由 GameWorld 生成后注入）
# var map_data: RadialGridMap
#
# ## 等距转换常量（预计算，避免重复除法）
# var _chunk_step_x: float
# var _chunk_step_y: float
# var _inv_chunk_step_x: float
# var _inv_chunk_step_y: float
#
# # ========================== 节点引用模块 ==========================
# ## 用于容纳所有区块 TileMapLayer 的容器节点
# @onready var _chunk_container: Node2D = $ChunkContainer
#
# # ========================== 生命周期模块 ==========================
# ## 功能：节点就绪时初始化区块管理器
# func _ready() -> void:
# 	if tileset == null:
# 		push_error("ChunkManager: tileset 未设置")
# 		return
#
# 	_tile_size = tileset.tile_size
#
# 	# 创建参考 TileMapLayer 用于坐标转换（不加入场景树）
# 	_reference_layer = TileMapLayer.new()
# 	_reference_layer.tile_set = tileset
#
# 	# 预计算等距转换常量
# 	_update_isometric_constants()
#
# 	# 查找或创建 ChunkContainer
# 	if _chunk_container == null:
# 		_chunk_container = Node2D.new()
# 		_chunk_container.name = "ChunkContainer"
# 		add_child(_chunk_container)
#
# 	# 确保等距渲染顺序：上方区块在下方区块之后渲染
# 	_chunk_container.y_sort_enabled = true
#
# 	# 查找可用的对象池
# 	_pool = $ChunkPool as ChunkPool
#
# 	# 延迟初始化，确保 Global.player 已被 LobbyWorld 定位到出生点
# 	call_deferred(&"_init_chunks")
#
# ## 功能：延迟初始化区块，等待玩家就绪
# func _init_chunks() -> void:
# 	var player := Global.player
# 	if not is_instance_valid(player):
# 		# 如果玩家尚未就绪，等待一帧后重试
# 		await get_tree().process_frame
# 		_init_chunks()
# 		return
#
# 	# 从 map_data 同步区块尺寸（优先使用配置值）
# 	if map_data != null and map_data.config != null:
# 		chunk_size = map_data.config.chunk_size
# 		_update_isometric_constants()
#
# 	# 计算玩家所在区块，并加载初始范围内的区块
# 	_last_player_chunk = _pixel_to_chunk(player.global_position)
#
# 	_load_chunks_around(_last_player_chunk)
# 	_notify_room_enter(_last_player_chunk)
#
# ## 功能：每帧检查玩家位置并更新区块
# ## 参数：delta (float) - 帧间隔时间
# func _process(delta: float) -> void:
# 	_accumulated_time += delta
# 	if _accumulated_time < check_interval:
# 		return
# 	_accumulated_time = 0.0
#
# 	_update_chunks()
#
# # ========================== 核心更新逻辑模块 ==========================
# ## 功能：检查玩家是否跨越了区块边界，若是则增量加载/卸载
# func _update_chunks() -> void:
# 	var player := Global.player
# 	if not is_instance_valid(player):
# 		return
#
# 	var player_chunk := _pixel_to_chunk(player.global_position)
#
# 	if player_chunk == _last_player_chunk:
# 		return
#
# 	_last_player_chunk = player_chunk
# 	_load_chunks_around(player_chunk)
# 	_notify_room_enter(player_chunk)
#
# ## 功能：围绕指定区块坐标加载范围内的所有区块，并卸载超出的
# ## 参数：center (Vector2i) - 中心区块坐标
# func _load_chunks_around(center: Vector2i) -> void:
# 	# 1. 计算目标加载集合
# 	var target_chunks: Array[Vector2i] = []
# 	for cx in range(center.x - load_radius, center.x + load_radius + 1):
# 		for cy in range(center.y - load_radius, center.y + load_radius + 1):
# 			target_chunks.append(Vector2i(cx, cy))
#
# 	# 2. 筛选出尚未加载的区块
# 	var to_load: Array[Vector2i] = []
# 	for coord in target_chunks:
# 		if not _loaded_chunks.has(_chunk_key(coord.x, coord.y)):
# 			to_load.append(coord)
#
# 	# 3. 按等距深度 (cx + cy) 升序排列
# 	#    深度值小的（更远）先加载/插入场景树，确保渲染在更后面
# 	to_load.sort_custom(_compare_xy)
#
# 	# 4. 卸载超出范围的区块
# 	var to_unload: Array[String] = []
# 	for key in _loaded_chunks:
# 		var coords := _parse_key(key)
# 		if abs(coords.x - center.x) > unload_radius or abs(coords.y - center.y) > unload_radius:
# 			to_unload.append(key)
#
# 	for key in to_unload:
# 		_unload_chunk(key)
#
# 	# 5. 按排序后的顺序加载新区块
# 	for coord in to_load:
# 		_load_chunk(coord.x, coord.y)
#
# # ========================== 区块加载/卸载模块 ==========================
# ## 功能：加载指定坐标的区块
# ## 参数：cx (int) - 区块 X 坐标；cy (int) - 区块 Y 坐标
# func _load_chunk(cx: int, cy: int) -> void:
# 	var key := _chunk_key(cx, cy)
#
# 	# 从对象池获取或新建 TileMapLayer
# 	var layer: TileMapLayer
# 	if _pool != null:
# 		layer = _pool.borrow()
# 	else:
# 		layer = TileMapLayer.new()
#
# 	layer.tile_set = tileset
# 	layer.name = "Chunk_%d_%d" % [cx, cy]
#
# 	# 设置 z_index 确保区块在实体下方
# 	layer.z_index = chunk_z_index
#
# 	# 定位：将节点放在区块原点（全局 tile (cx*size, cy*size) 的局部位置）
# 	layer.position = _tile_to_local(cx * chunk_size, cy * chunk_size)
#
# 	# 填充瓦片数据
# 	_fill_chunk(layer, cx, cy)
# 	# 加入场景树
# 	_chunk_container.add_child(layer)
# 	_loaded_chunks[key] = layer
# 	chunk_loaded.emit(cx, cy)
#
# ## 功能：卸载指定 key 对应的区块
# ## 参数：key (String) - 区块标识符 "cx,cy"
# func _unload_chunk(key: String) -> void:
# 	var layer: TileMapLayer = _loaded_chunks.get(key) as TileMapLayer
# 	if layer == null:
# 		return
#
# 	var coords := _parse_key(key)
#
# 	if _pool != null:
# 		layer.clear()
# 		layer.get_parent().remove_child(layer)
# 		_pool.return_chunk(layer)
# 	else:
# 		layer.queue_free()
#
# 	_loaded_chunks.erase(key)
# 	chunk_unloaded.emit(coords.x, coords.y)
#
# ## 功能：填充单个区块的瓦片数据
# ## 参数：layer (TileMapLayer) - 目标图层；chunk_x (int) - 区块 X；chunk_y (int) - 区块 Y
# func _fill_chunk(layer: TileMapLayer, chunk_x: int, chunk_y: int) -> void:
# 	if generator != null:
# 		var ring := get_ring(chunk_x, chunk_y)
# 		generator.fill_chunk(layer, chunk_size, chunk_x, chunk_y, world_seed, ring)
# 	else:
# 		# 无生成器时的兜底：生成空白草地
# 		_fill_default(layer, chunk_x, chunk_y)
#
# ## 功能：默认填充方式（无生成器时的备用方案）
# func _fill_default(layer: TileMapLayer, chunk_x: int, chunk_y: int) -> void:
# 	var rng := RandomNumberGenerator.new()
# 	rng.seed = _make_chunk_seed(chunk_x, chunk_y)
#
# 	for local_x in chunk_size:
# 		for local_y in chunk_size:
# 			var tile_variant := rng.randi_range(0, 9)
# 			var atlas_coords := Vector2i(tile_variant % 5, (tile_variant / 5.0) as int)
# 			layer.set_cell(Vector2i(local_x, local_y), 1, atlas_coords)
#
# # ========================== 工具方法模块 ==========================
# ## 功能：将世界坐标（像素）直接转换为区块坐标
# ## 使用自定义等距公式（与 Godot 的 map_to_local 互为反函数）
# ## 参数：pos - 世界像素坐标
# ## 返回值：Vector2i - 区块坐标 (cx, cy)
# func _pixel_to_chunk(pos: Vector2) -> Vector2i:
# 	var px := pos.x
# 	var py := pos.y
# 	var cx := floori(px * _inv_chunk_step_x + py * _inv_chunk_step_y)
# 	var cy := floori(py * _inv_chunk_step_y - px * _inv_chunk_step_x)
# 	return Vector2i(cx, cy)
#
# ## 预计算等距转换常量，在 tileset 或 chunk_size 变更时重新调用
# func _update_isometric_constants() -> void:
# 	var half_w: float
# 	var half_h: float
# 	if tileset == null or tileset.tile_size == Vector2i.ZERO:
# 		half_w = 16.0
# 		half_h = 8.0
# 	else:
# 		half_w = tileset.tile_size.x * 0.5
# 		half_h = tileset.tile_size.y * 0.5
#
# 	_chunk_step_x = chunk_size * half_w * 2.0
# 	_chunk_step_y = chunk_size * half_h * 2.0
# 	_inv_chunk_step_x = 1.0 / _chunk_step_x
# 	_inv_chunk_step_y = 1.0 / _chunk_step_y
#
# ## 功能：将 tile 坐标转换为局部位置（像素）
# ## 使用参考 TileMapLayer 的 map_to_local 确保与 Godot 内部坐标系一致
# func _tile_to_local(tx: int, ty: int) -> Vector2:
# 	return _reference_layer.map_to_local(Vector2i(tx, ty))
#
# ## 功能：生成区块坐标的唯一字符串 key
# static func _chunk_key(cx: int, cy: int) -> String:
# 	return "%d,%d" % [cx, cy]
#
# ## 功能：从 key 字符串解析回区块坐标
# static func _parse_key(key: String) -> Vector2i:
# 	var parts := key.split(",")
# 	if parts.size() == 2:
# 		return Vector2i(parts[0].to_int(), parts[1].to_int())
# 	return Vector2i.ZERO
#
# ## 功能：根据区块坐标生成确定性种子
# func _make_chunk_seed(cx: int, cy: int) -> int:
# 	return hash(cx * 73856093 ^ cy * 19349663 ^ world_seed * 83492791)
#
# static func _compare_xy(a: Vector2i, b: Vector2i) -> bool:
# 	return (a.x + a.y) < (b.x + b.y)
#
# # ========================== 公共 API 模块 ==========================
# ## 功能：强制重新加载所有区块（如切换生成器后调用）
# func reload_all() -> void:
# 	# 先卸载所有
# 	var keys := _loaded_chunks.keys()
# 	for key in keys:
# 		_unload_chunk(key)
# 	_last_player_chunk = Vector2i(999999, 999999)
#
# 	# 重新初始化
# 	_init_chunks()
#
# ## 功能：获取当前已加载的区块数量
# func get_loaded_chunk_count() -> int:
# 	return _loaded_chunks.size()
#
# ## 功能：检查指定坐标的区块是否已加载
# func is_chunk_loaded(cx: int, cy: int) -> bool:
# 	return _loaded_chunks.has(_chunk_key(cx, cy))
#
# ## 功能：获取指定区块的 ring 值（难度圈层）
# ## 从 map_data 查询，若无 map_data 则返回曼哈顿距离
# func get_ring(cx: int, cy: int) -> int:
# 	if map_data != null:
# 		var cell := map_data.get_cell(cx, cy)
# 		if cell != null:
# 			return cell.ring
# 	return abs(cx) + abs(cy)
#
# ## 功能：获取指定区块的事件类型
# ## 从 map_data 查询，若无 map_data 则返回空字符串
# func get_event_type(cx: int, cy: int) -> String:
# 	if map_data != null:
# 		var cell := map_data.get_cell(cx, cy)
# 		if cell != null:
# 			return cell.event_type
# 	return ""
#
# ## 获取坐标转换用的参考 TileMapLayer（用于 map_to_local 坐标换算）
# func get_ref_layer() -> TileMapLayer:
# 	return _reference_layer
#
# ## 通知 RoomManager 玩家进入了新格子
# func _notify_room_enter(coord: Vector2i) -> void:
# 	var ring := get_ring(coord.x, coord.y)
# 	var event := get_event_type(coord.x, coord.y)
# 	RoomManager.enter_room(coord, ring, event)
#
# ## 功能：清空所有已加载的区块，重置状态
# func clear_all() -> void:
# 	var keys := _loaded_chunks.keys()
# 	for key in keys:
# 		_unload_chunk(key)
# 	_last_player_chunk = Vector2i(999999, 999999)

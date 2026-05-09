# ==============================================================================
#   ChunkLoader.gd
#   功能：开放世界区块加载器——追踪玩家位置，以 3x3 视觉矩形网格加载/卸载区块
#         等距坐标系：屏幕 UP=(-1,-1), RIGHT=(1,-1), DOWN=(1,1), LEFT=(-1,1)
#         负责动态加载/卸载地图区块，优化性能
# ==============================================================================

class_name ChunkLoader
extends Node

# ========================== 信号声明 ==========================

## 触发时机：区块加载完成时
## 参数：cx - 区块 X 坐标，cy - 区块 Y 坐标，ring - 区块所在的圈层
signal chunk_loaded(cx: int, cy: int, ring: int)

## 触发时机：区块卸载完成时
## 参数：cx - 区块 X 坐标，cy - 区块 Y 坐标
signal chunk_unloaded(cx: int, cy: int)

# ========================== 导出变量 ==========================

## 地形瓦片集资源（setter 会在变更时自动更新缓存）
@export var tile_set: TileSet:
	set(value):
		tile_set = value
		_update_tile_cache()      # 瓦片集变化时重新计算有效瓦片列表
		_update_isometric_constants()  # 同时更新等距转换常量

## 每个区块的瓦片边长（单位：瓦片数）
@export var chunk_size: int = 48

## 加载半径（以玩家所在区块为中心，周围 N x N 区域内的区块保持加载）
@export var load_radius: int = 1

# ========================== 成员变量 ==========================
## 地图数据（包含网格房间信息）
var map_data: RadialGridMap

## 已加载的区块映射表：键 "cx,cy" → TileMapLayer
var _loaded: Dictionary = {}

## 上一帧玩家所在的区块坐标
var _last_chunk: Vector2i = Vector2i(999999, 999999)

## 引用图层（仅用于坐标转换，不加入场景树）
var _ref_layer: TileMapLayer

#========================== 瓦片缓存（性能优化）==========================
## 第一个图集源 ID
var _source_id: int = -1

## 第一个图集源对象
var _atlas_source: TileSetAtlasSource = null

## 所有有效瓦片的图集坐标（按行优先顺序，跳过空缺瓦片）
var _valid_tiles: Array[Vector2i] = []

# =================== 等距转换常量（预计算，避免重复除法）=====================
## 瓦片半宽（像素），默认 32x16 瓦片
var _tile_half_w: float = 16.0
## 瓦片半高（像素）
var _tile_half_h: float = 8.0
## 1 / _tile_half_w
var _inv_tile_half_w: float
## 1 / _tile_half_h
var _inv_tile_half_h: float
## 区块在 X 方向上的像素跨度
var _chunk_step_x: float
## 区块在 Y 方向上的像素跨度
var _chunk_step_y: float
var _inv_chunk_step_x: float
var _inv_chunk_step_y: float

# ========================== 节点引用 ==========================

## 区块容器节点
@onready var _container: Node2D = $ChunkContainer
## 区块对象池节点
@onready var _pool: ChunkPool = $ChunkPool

# ========================== 生命周期 ==========================

## 功能：节点进入场景树时调用
## 初始化容器、区块池和坐标转换引用图层
func _ready() -> void:
	clear_all()
	_init_containers()
	_init_ref_layer()
	# 计算有效瓦片坐标列表
	_update_tile_cache()
	# 计算等距转换相关常量
	_update_isometric_constants()
	
## 功能：创建引用图层用于等距坐标转换（不加入场景树）
func _init_ref_layer() -> void:
	_ref_layer = TileMapLayer.new()
	_ref_layer.tile_set = tile_set

## 功能：确保区块容器和对象池节点存在
func _init_containers() -> void:
	if _container == null:
		_container = Node2D.new()
		_container.name = "ChunkContainer"
		add_child(_container)
	if _pool == null:
		_pool = ChunkPool.new()
		_pool.name = "ChunkPool"
		add_child(_pool)
		
## 功能：每帧更新，追踪玩家位置并刷新区块加载区域
## 参数：_delta - 帧间隔时间（未使用）
func _process(_delta: float) -> void:
	var player := Global.player
	if not is_instance_valid(player):
		return
	
	# 直接计算区块坐标，绕过 local_to_map 的半偏移布局问题
	var current_chunk := _pixel_to_chunk(player.global_position)
	
	# 若区块坐标未变化则跳过刷新
	if current_chunk == _last_chunk:
		return
	
	_last_chunk = current_chunk
	print("ChunkLoader: 玩家移动到区块 (%d, %d)" % [current_chunk.x, current_chunk.y])
	_refresh(current_chunk.x, current_chunk.y)

# ========================== 缓存更新 ==========================

## 功能：从 tile_set 中提取所有有效瓦片坐标（跳过空缺瓦片）
## 结果存储在 _valid_tiles 中，按行优先顺序排列
func _update_tile_cache() -> void:
	_valid_tiles.clear()
	_source_id = -1
	_atlas_source = null
	
	if tile_set == null or tile_set.get_source_count() == 0:
		return
	
	_source_id = tile_set.get_source_id(0)
	var source = tile_set.get_source(_source_id) as TileSetAtlasSource
	if not source is TileSetAtlasSource:
		return
	
	_atlas_source = source
	var grid_size := source.get_atlas_grid_size()
	for y in grid_size.y:
		for x in grid_size.x:
			var coords := Vector2i(x, y)
			if source.has_tile(coords):
				_valid_tiles.append(coords)

## 功能：根据瓦片实际尺寸计算等距转换所需常量
## 包括瓦片半宽半高、区块像素跨度及其倒数，用于快速坐标转换
func _update_isometric_constants() -> void:
	if tile_set == null or tile_set.tile_size == Vector2i.ZERO:
		# 回退默认值（标准 32x16 等距瓦片）
		_tile_half_w = 16.0
		_tile_half_h = 8.0
	else:
		_tile_half_w = tile_set.tile_size.x * 0.5
		_tile_half_h = tile_set.tile_size.y * 0.5
	
	_inv_tile_half_w = 1.0 / _tile_half_w
	_inv_tile_half_h = 1.0 / _tile_half_h
	
	# 区块在等距网格中的像素跨度（单边长度）
	# = chunk_size * tile_width
	_chunk_step_x = chunk_size * _tile_half_w * 2.0
	# = chunk_size * tile_height
	_chunk_step_y = chunk_size * _tile_half_h * 2.0
	_inv_chunk_step_x = 1.0 / _chunk_step_x
	_inv_chunk_step_y = 1.0 / _chunk_step_y

# ========================== 私有方法（坐标转换） ==========================

## 功能：直接从像素位置反算区块坐标
## 参数：pos - 世界像素坐标
## 返回值：Vector2i - 区块坐标 (cx, cy)
## 原理：基于等距投影公式 px = (cx - cy) * half_w * cs，py = (cx + cy) * half_h * cs
##       反解得：cx = px/(cs*2*half_w) + py/(cs*2*half_h)
##               cy = py/(cs*2*half_h) - px/(cs*2*half_w)
func _pixel_to_chunk(pos: Vector2) -> Vector2i:
	var px := pos.x
	var py := pos.y
	var cx := floori(px * _inv_chunk_step_x + py * _inv_chunk_step_y)
	var cy := floori(py * _inv_chunk_step_y - px * _inv_chunk_step_x)
	return Vector2i(cx, cy)

# ========================== 私有方法（区块管理） ==========================

## 功能：以 (center_cx, center_cy) 为中心刷新 (2*load_radius+1) x (2*load_radius+1) 的区块网格
## 参数：center_cx - 中心区块 X 坐标，center_cy - 中心区块 Y 坐标
## 处理流程：计算目标区块集合 → 卸载超出范围的区块 → 加载缺失的区块
func _refresh(center_cx: int, center_cy: int) -> void:
	# 生成目标区块坐标集
	var target_positions: Array[Vector2i] = []
	for dy in range(-load_radius, load_radius + 1):
		for dx in range(-load_radius, load_radius + 1):
			target_positions.append(Vector2i(center_cx + dx, center_cy + dy))
	
	# 构建快速查找字典
	var target_dict := {}
	for pos in target_positions:
		target_dict[_key(pos.x, pos.y)] = pos

	print("ChunkLoader: %dx%d 目标区块 = " % [(load_radius * 2 + 1), (load_radius * 2 + 1)], target_dict.values())
	
	# 卸载超出范围的区块
	for key in _loaded.keys():
		if not target_dict.has(key):
			_unload(key)
	
	# 加载缺失的区块
	for key in target_dict:
		if not _loaded.has(key):
			var pos :Vector2i = target_dict[key]
			_load(pos.x, pos.y)

## 功能：加载单个区块
## 参数：cx - 区块 X 坐标，cy - 区块 Y 坐标
func _load(cx: int, cy: int) -> void:
	var ring := _resolve_ring(cx, cy)
	var key := _key(cx, cy)
	
	# 从对象池借用 TileMapLayer
	var layer := _pool.borrow()
	layer.tile_set = tile_set
	layer.name = "Chunk_%d_%d" % [cx, cy]
	layer.z_index = -1
	# 防御性清除，确保没有残留瓦片
	layer.clear()
	
	# 用 map_to_local 定位区块原点（等距对齐）
	var origin = _ref_layer.map_to_local(Vector2i(cx * chunk_size, cy * chunk_size))
	layer.position = origin
	
	print("ChunkLoader: 加载区块 (%d, %d), ring=%d, 位置=(%.1f, %.1f)" 
		% [cx, cy, ring, origin.x, origin.y])
	
	# 填充区块瓦片
	_fill_ring_tiles(layer, ring)
	
	# 添加到容器并调整渲染顺序
	_container.add_child(layer)
	_insert_by_depth(layer)
	
	_loaded[key] = layer
	chunk_loaded.emit(cx, cy, ring)

## 功能：按等距深度插入区块，确保渲染顺序正确
## 参数：layer - 待插入的 TileMapLayer
## 等距渲染规则：屏幕 Y 越小（越靠上/越远）→ 先渲染（更后面）
func _insert_by_depth(layer: TileMapLayer) -> void:
	var depth_y := layer.position.y
	var insert_idx := _container.get_child_count() - 1  # 默认末尾
	
	for i in _container.get_child_count():
		var child := _container.get_child(i) as TileMapLayer
		if child == layer:
			continue
		if child.position.y > depth_y:
			insert_idx = i
			break
	
	_container.move_child(layer, insert_idx)

## 功能：卸载单个区块
## 参数：key - 区块映射键（格式 "cx,cy"）
func _unload(key: String) -> void:
	var layer := _loaded.get(key) as TileMapLayer
	if layer == null:
		return
	
	layer.clear()
	if layer.get_parent() != null:
		layer.get_parent().remove_child(layer)
	
	_pool.return_chunk(layer)
	_loaded.erase(key)
	
	var parts := key.split(",")
	if parts.size() == 2:
		chunk_unloaded.emit(parts[0].to_int(), parts[1].to_int())

## 功能：用指定圈层的瓦片平铺整个区块
## 参数：layer - 目标 TileMapLayer，ring - 圈层索引（决定使用的瓦片样式）
func _fill_ring_tiles(layer: TileMapLayer, ring: int) -> void:
	if _valid_tiles.is_empty() or _source_id == -1:
		return
	
	var tile_index := ring % _valid_tiles.size()
	var atlas_coords := _valid_tiles[tile_index]
		
	# 平铺整个区块（chunk_size 为成员变量）
	for x in chunk_size:
		for y in chunk_size:
			layer.set_cell(Vector2i(x, y), _source_id, atlas_coords)

# ========================== 辅助函数 ==========================

## 功能：解析区块坐标对应的圈层
## 参数：cx - 区块 X 坐标，cy - 区块 Y 坐标
## 返回值：int - 圈层索引（曼哈顿距离）
func _resolve_ring(cx: int, cy: int) -> int:
	if map_data != null:
		var cell := map_data.get_cell(cx, cy)
		if cell != null:
			return cell.ring
	return abs(cx) + abs(cy)

## 功能：清空所有已加载的区块
func clear_all() -> void:
	for key in _loaded.keys():
		_unload(key)
	_last_chunk = Vector2i(999999, 999999)

## 功能：生成区块映射键
## 参数：cx - 区块 X 坐标，cy - 区块 Y 坐标
## 返回值：String - 格式为 "cx,cy" 的键字符串
static func _key(cx: int, cy: int) -> String:
	return "%d,%d" % [cx, cy]

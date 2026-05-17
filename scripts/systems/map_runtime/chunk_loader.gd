# ==============================================================================
#   ChunkLoader.gd（已废弃）
#   功能：已被 ChunkManager 取代。保留此文件供临时参考，后续将删除。
#         请使用 ChunkManager（scripts/systems/map_generation/chunk_manager.gd）。
# ==============================================================================
extends Node
class_name ChunkLoader

# ========================== 信号声明模块 ==========================
signal chunk_loaded(cx: int, cy: int, ring: int)
signal chunk_unloaded(cx: int, cy: int)

# ========================== 导出变量模块 ==========================
@export var tile_set: TileSet
@export var chunk_size: int = 48
@export var load_radius: int = 1

# ========================== 变量定义模块 ==========================
var map_data: RadialGridMap
var _loaded: Dictionary = {}
var _last_chunk: Vector2i = Vector2i(999999, 999999)
var _ref_layer: TileMapLayer
var _source_id: int = -1
var _atlas_source: TileSetAtlasSource = null
var _valid_tiles: Array[Vector2i] = []
var _tile_half_w: float = 16.0
var _tile_half_h: float = 8.0
var _inv_tile_half_w: float
var _inv_tile_half_h: float
var _chunk_step_x: float
var _chunk_step_y: float
var _inv_chunk_step_x: float
var _inv_chunk_step_y: float

# ========================== 节点引用模块 ==========================
@onready var _container: Node2D = $ChunkContainer
@onready var _pool: ChunkPool = $ChunkPool

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	clear_all()
	_init_containers()
	_init_ref_layer()
	_update_tile_cache()
	_update_isometric_constants()

# ========================== 内部方法模块 ==========================
func _init_ref_layer() -> void:
	_ref_layer = TileMapLayer.new()
	_ref_layer.tile_set = tile_set

func _init_containers() -> void:
	if _container == null:
		_container = Node2D.new()
		_container.name = "ChunkContainer"
		add_child(_container)
	if _pool == null:
		_pool = ChunkPool.new()
		_pool.name = "ChunkPool"
		add_child(_pool)

func _process(_delta: float) -> void:
	var player := Global.player
	if not is_instance_valid(player):
		return
	var current_chunk := _pixel_to_chunk(player.global_position)
	if current_chunk == _last_chunk:
		return
	_last_chunk = current_chunk
	_refresh(current_chunk.x, current_chunk.y)

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

func _update_isometric_constants() -> void:
	if tile_set == null or tile_set.tile_size == Vector2i.ZERO:
		_tile_half_w = 16.0
		_tile_half_h = 8.0
	else:
		_tile_half_w = tile_set.tile_size.x * 0.5
		_tile_half_h = tile_set.tile_size.y * 0.5
	_inv_tile_half_w = 1.0 / _tile_half_w
	_inv_tile_half_h = 1.0 / _tile_half_h
	_chunk_step_x = chunk_size * _tile_half_w * 2.0
	_chunk_step_y = chunk_size * _tile_half_h * 2.0
	_inv_chunk_step_x = 1.0 / _chunk_step_x
	_inv_chunk_step_y = 1.0 / _chunk_step_y

func _pixel_to_chunk(pos: Vector2) -> Vector2i:
	var px := pos.x
	var py := pos.y
	var cx := floori(px * _inv_chunk_step_x + py * _inv_chunk_step_y)
	var cy := floori(py * _inv_chunk_step_y - px * _inv_chunk_step_x)
	return Vector2i(cx, cy)

func _refresh(center_cx: int, center_cy: int) -> void:
	var target_positions: Array[Vector2i] = []
	for dy in range(-load_radius, load_radius + 1):
		for dx in range(-load_radius, load_radius + 1):
			target_positions.append(Vector2i(center_cx + dx, center_cy + dy))
	var target_dict := {}
	for pos in target_positions:
		target_dict[_key(pos.x, pos.y)] = pos
	for key in _loaded.keys():
		if not target_dict.has(key):
			_unload(key)
	for key in target_dict:
		if not _loaded.has(key):
			var pos :Vector2i = target_dict[key]
			_load(pos.x, pos.y)

func _load(cx: int, cy: int) -> void:
	var ring := _resolve_ring(cx, cy)
	var key := _key(cx, cy)
	var layer := _pool.borrow()
	layer.tile_set = tile_set
	layer.name = "Chunk_%d_%d" % [cx, cy]
	layer.z_index = -1
	layer.clear()
	var origin = _ref_layer.map_to_local(Vector2i(cx * chunk_size, cy * chunk_size))
	layer.position = origin
	_fill_ring_tiles(layer, ring)
	_container.add_child(layer)
	_insert_by_depth(layer)
	_loaded[key] = layer
	chunk_loaded.emit(cx, cy, ring)

func _insert_by_depth(layer: TileMapLayer) -> void:
	var depth_y := layer.position.y
	var insert_idx := _container.get_child_count() - 1
	for i in _container.get_child_count():
		var child := _container.get_child(i) as TileMapLayer
		if child == layer:
			continue
		if child.position.y > depth_y:
			insert_idx = i
			break
	_container.move_child(layer, insert_idx)

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

func _fill_ring_tiles(layer: TileMapLayer, ring: int) -> void:
	if _valid_tiles.is_empty() or _source_id == -1:
		return
	var tile_index := ring % _valid_tiles.size()
	var atlas_coords := _valid_tiles[tile_index]
	for x in chunk_size:
		for y in chunk_size:
			layer.set_cell(Vector2i(x, y), _source_id, atlas_coords)

func _resolve_ring(cx: int, cy: int) -> int:
	if map_data != null:
		var cell := map_data.get_cell(cx, cy)
		if cell != null:
			return cell.ring
	return abs(cx) + abs(cy)

func clear_all() -> void:
	for key in _loaded.keys():
		_unload(key)
	_last_chunk = Vector2i(999999, 999999)

static func _key(cx: int, cy: int) -> String:
	return "%d,%d" % [cx, cy]

# ==============================================================================
#   terrain_generator.gd
#   功能：基于 BFS 区域生长法生成带有不规则连片水域的地形，
#         并根据草地/水域的邻接方向自动选择过渡瓦片。
#        通过与 BiomeMap + BiomeConfig 配合支持多生态扩展。
#   用法：创建实例后设置 biome_map，然后赋值给 ChunkManager.generator。
# ==============================================================================
extends RefCounted
class_name TerrainGenerator

## 生态地图引用。若为 null 则使用兜底数据
var biome_map: BiomeMap = null

# ========================== 瓦片布局常量 ==========================
## Diamond Bottom 等距瓦片的 4 个菱形邻接方向
## 方向索引 0=SE, 1=SW, 2=NW, 3=NE
const DIR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),   # 方向 0: SE（右下）
	Vector2i(0, 1),   # 方向 1: SW（左下）
	Vector2i(-1, 0),  # 方向 2: NW（左上）
	Vector2i(0, -1),  # 方向 3: NE（右上）
]

## 方向->图集索引映射。若图集中过渡瓦片排列不同，新建常量覆盖即可
const DIR_ORDER: Array[int] = [0, 1, 2, 3]

## 邻居区块偏移列表（5 个：自身 + 四方向相邻）
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
]

# ========================== 兜底配置（无 BiomeMap 时使用） ==========================
## 草地瓦片调色板（图集第 0 行）
const _FALLBACK_GROUND: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
]

## 水域瓦片调色板（图集第 1 行）
const _FALLBACK_WATER: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
]

const _FALLBACK_SOURCE_ID: int = 1

# ========================== 公共 API 模块 ==========================
## 功能：填充指定区块的 TileMapLayer，带过渡瓦片选择
func fill_chunk(layer: TileMapLayer, chunk_x: int, chunk_y: int, base_seed: int) -> void:
	var size := _get_chunk_size(layer)

	# 获取当前区块的生态配置（无 biome_map 时用兜底）
	var biome := _get_biome(chunk_x, chunk_y, base_seed)

	# 1. 收集当前区块范围内所有水池瓦片的全局坐标
	var water_set := _collect_water_in_region(chunk_x, chunk_y, size, base_seed, biome)

	# 2. 构建扩展 terrain 地图（含相邻 1 格边界，用于方向检查）
	var terrain := _build_terrain_map(chunk_x, chunk_y, size, water_set, base_seed, biome)

	# 3. 填充，带过渡瓦片选择
	for lx in size:
		for ly in size:
			var global_pos := Vector2i(chunk_x * size + lx, chunk_y * size + ly)
			var atlas_coords: Vector2i
			if water_set.has(global_pos):
				atlas_coords = _pick_water_tile(global_pos, terrain, biome)
			else:
				atlas_coords = _pick_ground_tile(global_pos, terrain, biome)

			layer.set_cell(Vector2i(lx, ly), biome.source_id if biome_map != null else _FALLBACK_SOURCE_ID, atlas_coords)

# ========================== 生态查询模块 ==========================
## 获取指定区块的生态配置（带 null 安全兜底）
func _get_biome(chunk_x: int, chunk_y: int, base_seed: int) -> BiomeConfig:
	if biome_map != null:
		return biome_map.get_biome(chunk_x, chunk_y, base_seed)
	return null

## 从 BiomeConfig 获取地面瓦片调色板（带兜底）
func _get_ground_palette(biome: BiomeConfig) -> Array[Vector2i]:
	if biome != null and not biome.ground_palette.is_empty():
		return biome.ground_palette
	return _FALLBACK_GROUND

## 从 BiomeConfig 获取水域瓦片调色板（带兜底）
func _get_water_palette(biome: BiomeConfig) -> Array[Vector2i]:
	if biome != null and not biome.water_palette.is_empty():
		return biome.water_palette
	return _FALLBACK_WATER

## 从 BiomeConfig 获取生成参数（带兜底）
func _get_param(biome: BiomeConfig, name: String, default_val):
	if biome != null:
		var args =  biome.get(name)
		if args != null:
			return args
		else:
			return default_val
	return default_val

# ========================== 核心：跨区块水池收集模块 ==========================
## 功能：收集当前区块及邻居区块内产生的、落在当前区块范围内的水池瓦片
func _collect_water_in_region(chunk_x: int, chunk_y: int, size: int,
		base_seed: int, biome: BiomeConfig) -> Dictionary:

	var water: Dictionary = {}
	var chunk_min_x := chunk_x * size
	var chunk_min_y := chunk_y * size
	var chunk_max_x := chunk_min_x + size - 1
	var chunk_max_y := chunk_min_y + size - 1

	for pair in NEIGHBOR_OFFSETS:
		var nc_x := chunk_x + pair.x
		var nc_y := chunk_y + pair.y
		var bodies := _generate_water_bodies_in_expanded(nc_x, nc_y, size, base_seed, biome)

		for pos in bodies:
			if pos.x >= chunk_min_x and pos.x <= chunk_max_x \
					and pos.y >= chunk_min_y and pos.y <= chunk_max_y:
				water[pos] = true

	return water

## 构建含 1 格边界扩展的 terrain 查找表
func _build_terrain_map(chunk_x: int, chunk_y: int, size: int,
		water_set: Dictionary, base_seed: int, biome: BiomeConfig) -> Dictionary:

	var terrain: Dictionary = {}
	var min_x := chunk_x * size - 1
	var min_y := chunk_y * size - 1
	var max_x := (chunk_x + 1) * size
	var max_y := (chunk_y + 1) * size

	var extended_water := _collect_edge_water(chunk_x, chunk_y, size, base_seed, biome)

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos := Vector2i(x, y)
			terrain[pos] = water_set.has(pos) or extended_water.has(pos)

	return terrain

## 收集当前区块边界外 1 格的水池数据（仅用于过渡瓦片方向判断）
func _collect_edge_water(chunk_x: int, chunk_y: int, size: int,
		base_seed: int, biome: BiomeConfig) -> Dictionary:

	var edge_water: Dictionary = {}
	var min_x := chunk_x * size - 1
	var min_y := chunk_y * size - 1
	var max_x := (chunk_x + 1) * size
	var max_y := (chunk_y + 1) * size

	for pair in NEIGHBOR_OFFSETS:
		var nc_x := chunk_x + pair.x
		var nc_y := chunk_y + pair.y
		var bodies := _generate_water_bodies_in_expanded(nc_x, nc_y, size, base_seed, biome)

		for pos in bodies:
			if pos.x >= min_x and pos.x <= max_x \
					and pos.y >= min_y and pos.y <= max_y:
				var in_core := pos.x >= chunk_x * size and pos.x < (chunk_x + 1) * size \
						and pos.y >= chunk_y * size and pos.y < (chunk_y + 1) * size
				if not in_core:
					edge_water[pos] = true

	return edge_water

# ========================== BFS 区域生长模块 ==========================
## 在指定区块的「扩展边界」内生成所有水池
func _generate_water_bodies_in_expanded(chunk_x: int, chunk_y: int, size: int,
		base_seed: int, biome: BiomeConfig) -> Array[Vector2i]:

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(chunk_x, chunk_y)) ^ base_seed

	var density := _get_param(biome, "water_density", 0.35) as float
	if rng.randf() > density:
		return []

	var padding := _get_param(biome, "bfs_padding", 5) as int
	var min_size := _get_param(biome, "water_body_size_min", 5) as int
	var max_size := _get_param(biome, "water_body_size_max", 15) as int

	var sx := chunk_x * size + rng.randi_range(padding, size - 1 - padding)
	var sy := chunk_y * size + rng.randi_range(padding, size - 1 - padding)
	var new_seed := Vector2i(sx, sy)

	var target := rng.randi_range(min_size, max_size)
	return _grow_region(new_seed, target, chunk_x, chunk_y, size, padding, base_seed)

## BFS 区域生长
func _grow_region(new_seed: Vector2i, target_size: int, chunk_x: int, chunk_y: int,
		size: int, padding: int, base_seed: int) -> Array[Vector2i]:

	var region: Array[Vector2i] = [new_seed]
	var min_x := chunk_x * size - padding
	var min_y := chunk_y * size - padding
	var max_x := (chunk_x + 1) * size - 1 + padding
	var max_y := (chunk_y + 1) * size - 1 + padding

	var frontier := _get_neighbors_in_rect(new_seed, min_x, min_y, max_x, max_y)
	var frontier_set := {}
	for f in frontier:
		frontier_set[f] = true

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(new_seed) ^ base_seed ^ 0xDEAD

	while region.size() < target_size and frontier.size() > 0:
		var idx := rng.randi_range(0, frontier.size() - 1)
		var pos := frontier[idx]
		frontier.remove_at(idx)
		frontier_set.erase(pos)

		if pos in region:
			continue

		region.append(pos)

		for nb in _get_neighbors_in_rect(pos, min_x, min_y, max_x, max_y):
			if not (nb in region) and not frontier_set.has(nb):
				frontier.append(nb)
				frontier_set[nb] = true

	return region

# ========================== 过渡瓦片选择模块 ==========================
## 为地面瓦片选择正确的图集坐标
func _pick_ground_tile(pos: Vector2i, terrain: Dictionary, biome: BiomeConfig) -> Vector2i:
	var palette := _get_ground_palette(biome)
	var trans := biome.ground_transition if biome != null and not biome.ground_transition.is_empty() else []
	var full_idx := _get_param(biome, "ground_full_index", 4) as int

	var water_dirs: Array[int] = []
	for dir_idx in 4:
		var neighbor := pos + DIR_OFFSETS[dir_idx]
		if terrain.get(neighbor, false):
			water_dirs.append(dir_idx)

	if water_dirs.is_empty():
		return palette[full_idx]
	elif not trans.is_empty():
		return trans[DIR_ORDER[water_dirs[0]]]
	else:
		return palette[DIR_ORDER[water_dirs[0]]]

## 为水域瓦片选择正确的图集坐标
func _pick_water_tile(pos: Vector2i, terrain: Dictionary, biome: BiomeConfig) -> Vector2i:
	var palette := _get_water_palette(biome)
	var trans := biome.water_transition if biome != null and not biome.water_transition.is_empty() else []
	var full_idx := _get_param(biome, "water_full_index", 4) as int

	var grass_dirs: Array[int] = []
	for dir_idx in 4:
		var neighbor := pos + DIR_OFFSETS[dir_idx]
		if not terrain.get(neighbor, true):
			grass_dirs.append(dir_idx)

	if grass_dirs.is_empty():
		return palette[full_idx]
	elif not trans.is_empty():
		return trans[DIR_ORDER[grass_dirs[0]]]
	else:
		return palette[DIR_ORDER[grass_dirs[0]]]

# ========================== 工具方法模块 ==========================
## 获取某瓦片在指定矩形范围内的邻居（八连通）
static func _get_neighbors_in_rect(pos: Vector2i, min_x: int, min_y: int, max_x: int, max_y: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx :int = pos.x + dx
			var ny :int = pos.y + dy
			if nx >= min_x and nx <= max_x and ny >= min_y and ny <= max_y:
				result.append(Vector2i(nx, ny))
	return result

## 从 TileMapLayer 获取区块大小
func _get_chunk_size(layer: TileMapLayer) -> int:
	var parent := layer.get_parent()
	while parent != null:
		if parent is ChunkManager:
			return (parent as ChunkManager).chunk_size
		parent = parent.get_parent()
	return 16

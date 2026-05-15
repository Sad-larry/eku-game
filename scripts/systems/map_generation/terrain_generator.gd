# ==============================================================================
#   terrain_generator.gd
#   功能：使用噪声高度图驱动地形生成。
#         通过 NoiseHeightGenerator 生成高度图，
#         TerrainHeightRules 将高度映射为 10 种地形类型，
#         最终铺设对应瓦片到 TileMapLayer。
#   ===== 重构说明 =====
#   移除：BFS 水域区域生长系统、过渡瓦片选择逻辑、地面/水域双调色板。
#   新增：NoiseHeightGenerator 高度图驱动、TerrainHeightRules 地形映射。
#   瓦片约定：图集以行顺序排列，index 0=深水、1=浅水 … 9=雪地。
# ==============================================================================
extends RefCounted
class_name TerrainGenerator

# ========================== 外部依赖模块 ==========================
## 生态地图引用（决定各区块使用哪个生态的瓦片图集）
var biome_map: BiomeMap = null

## 噪声高度图生成器（必须设置）
var height_generator: NoiseHeightGenerator = null

## 高度→地形类型映射规则（必须设置）
var height_rules: TerrainHeightRules = null

# ========================== 兜底配置模块 ==========================
## 无 biome_map 时的默认图集源 ID
const _FALLBACK_SOURCE_ID: int = 1

## 无 height_generator/height_rules 时的默认地形瓦片索引（草地）
const _FALLBACK_TILE_INDEX: int = 4

# ========================== 公共 API 模块 ==========================
## 填充指定区块的 TileMapLayer
func fill_chunk(layer: TileMapLayer, chunk_x: int, chunk_y: int, base_seed: int) -> void:
	var size := _get_chunk_size(layer)
	var biome := _get_biome(chunk_x, chunk_y, base_seed)
	var source := biome.source_id if biome != null else _FALLBACK_SOURCE_ID

	# 依赖缺失时用兜底填充
	if height_generator == null or height_rules == null:
		_fill_default(layer, size, source)
		return

	# 1. 生成当前区块的高度图
	#    使用全局坐标连续采样，保证区块间无缝衔接
	var height_map := height_generator.generate(
		size, size, base_seed,
		chunk_x * size, chunk_y * size
	)

	# 2. 高度图驱动瓦片选择
	for lx in size:
		for ly in size:
			var h := height_map.get_height(lx, ly)
			var terrain_type := height_rules.get_terrain_type(h)
			# 图集以行顺序排列：列=地形类型索引，行=0
			layer.set_cell(Vector2i(lx, ly), source, Vector2i(terrain_type, 0))

# ========================== 生态查询模块 ==========================
## 获取指定区块的生态配置
func _get_biome(chunk_x: int, chunk_y: int, base_seed: int) -> BiomeConfig:
	if biome_map != null:
		return biome_map.get_biome(chunk_x, chunk_y, base_seed)
	return null

# ========================== 工具方法模块 ==========================
## 兜底填充：统一铺默认地形瓦片
func _fill_default(layer: TileMapLayer, size: int, source: int) -> void:
	for lx in size:
		for ly in size:
			layer.set_cell(Vector2i(lx, ly), source, Vector2i(_FALLBACK_TILE_INDEX, 0))

## 从父级 ChunkManager 获取区块大小
func _get_chunk_size(layer: TileMapLayer) -> int:
	var parent := layer.get_parent()
	while parent != null:
		if parent is ChunkManager:
			return (parent as ChunkManager).chunk_size
		parent = parent.get_parent()
	return 32

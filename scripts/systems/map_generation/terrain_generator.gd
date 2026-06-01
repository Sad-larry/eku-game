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
# [重构注释] 2.5D等距地图相关代码已暂时禁用
# extends RefCounted
# class_name TerrainGenerator
#
# # ========================== 常量定义模块 ==========================
# ## 无 biome_map 时的默认图集源 ID
# const _FALLBACK_SOURCE_ID: int = 1
#
# ## 无 height_generator/height_rules 时的默认地形瓦片索引（草地）
# const _FALLBACK_TILE_INDEX: int = 4
#
# # ========================== 变量定义模块 ==========================
# ## 默认生态（当 ring 未在 ring_biomes 中设置时使用此生态）
# var default_biome: BiomeConfig = null
#
# ## ring→生态映射表（int(ring) → BiomeConfig）
# var ring_biomes: Dictionary = {}
#
# ## 噪声高度图生成器（必须设置）
# var height_generator: NoiseHeightGenerator = null
#
# ## 全局高度→地形类型映射规则（当 BiomeConfig 未设置自有的 height_rules 时使用）
# var height_rules: TerrainHeightRules = null
#
# # ========================== 公共 API 模块 ==========================
# ## 填充指定区块的 TileMapLayer
# ## 参数：layer (TileMapLayer) - 目标图层；size (int) - 区块大小；
# ##      chunk_x (int) - 区块 X 坐标；chunk_y (int) - 区块 Y 坐标；
# ##      base_seed (int) - 基础种子；ring (int) - 环数（默认 -1）
# func fill_chunk(layer: TileMapLayer, size: int, chunk_x: int, chunk_y: int, base_seed: int, ring: int = -1) -> void:
# 	# 根据 ring 获取生态配置
# 	var biome := _get_biome(ring)
# 	var rules := biome.height_rules if biome != null and biome.height_rules != null else height_rules
# 	var source := biome.source_id if biome != null else _FALLBACK_SOURCE_ID
#
# 	# 依赖缺失时用兜底填充
# 	if height_generator == null or rules == null:
# 		_fill_default(layer, size, source)
# 		return
#
# 	# 1. 生成当前区块的高度图
# 	#    使用全局坐标连续采样，保证区块间无缝衔接
# 	var height_map := height_generator.generate(
# 		size, size, base_seed,
# 		chunk_x * size, chunk_y * size
# 	)
#
# 	# 2. 应用生态高度偏移，整体抬升/压低地形态
# 	var bias := biome.height_bias if biome != null else 0.0
#
# 	# 3. 高度图驱动瓦片选择
# 	for lx in size:
# 		for ly in size:
# 			var h := height_map.get_height(lx, ly) + bias
# 			var terrain_type := rules.get_terrain_type(h)
# 			# 图集以行顺序排列：列=地形类型索引，行=0
# 			layer.set_cell(Vector2i(lx, ly), source, Vector2i(terrain_type, 0))
#
# # ========================== 生态查询模块 ==========================
# ## 根据 ring 值获取生态配置
# ## 优先从 ring_biomes 中查找，未设置则返回 default_biome
# func _get_biome(ring: int) -> BiomeConfig:
# 	if ring >= 0 and ring_biomes.has(ring):
# 		return ring_biomes[ring]
# 	return default_biome
#
# # ========================== 工具方法模块 ==========================
# ## 兜底填充：统一铺默认地形瓦片
# func _fill_default(layer: TileMapLayer, size: int, source: int) -> void:
# 	for lx in size:
# 		for ly in size:
# 			layer.set_cell(Vector2i(lx, ly), source, Vector2i(_FALLBACK_TILE_INDEX, 0))

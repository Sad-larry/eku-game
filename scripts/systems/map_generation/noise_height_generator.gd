# ==============================================================================
#   noise_height_generator.gd
#   功能：使用 FastNoiseLite 生成噪声高度图。
#         采用全局连续噪声采样（offset_x/offset_y），
#         确保区块间无缝衔接——相邻区块的相邻瓦片在连续的噪声场中采样。
#   用法：创建实例，配置噪声参数，调用 generate() 获取 HeightMap。
# ==============================================================================
# [重构注释] 2.5D等距地图相关代码已暂时禁用
# extends RefCounted
# class_name NoiseHeightGenerator
#
# # ========================== 变量定义模块 ==========================
# ## 噪声类型（FastNoiseLite.TYPE_*）
# var noise_type: int = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
#
# ## 噪声频率。值越小地形起伏越平缓。
# ## 注意：这是瓦片级坐标的频率（默认 0.1 ≈ 每 10 个瓦片一个起伏周期）
# var frequency: float = 0.1
#
# ## 分形类型（FastNoiseLite.FRACTAL_*）
# var fractal_type: int = FastNoiseLite.FRACTAL_FBM
#
# ## 分形叠加层数。层数越多细节越丰富，但性能开销越大
# var fractal_octaves: int = 3
#
# ## 分形倍率。值越大高频细节越丰富（建议 2.0）
# var lacunarity: float = 2.0
#
# ## 分形增益。值越小高频分量越弱（建议 0.5）
# var gain: float = 0.5
#
# ## 高度缩放系数。控制地形起伏幅度（1.0 时值域约 [-1, 1]）
# var height_scale: float = 1.0
#
# ## 垂直偏移量。整体抬高或降低地形（可用于海洋平面调整）
# var height_offset: float = 0.0
#
# # ========================== 公共 API 模块 ==========================
# ## 生成指定尺寸的高度图。
# ## 参数：
# ##   width    - 宽度（采样点数）
# ##   height   - 高度（采样点数）
# ##   map_seed - 随机种子，同种子同结果
# ##   offset_x / offset_y - 全局瓦片坐标偏移，用于区块定位。
# ##     TerrainGenerator 调用时传入 (chunk_x * chunk_size, chunk_y * chunk_size)，
# ##     使所有区块在同一个全局噪声场中采样，保证边界无缝。
# ## 返回值：HeightMap - 生成的噪声高度图
# func generate(width: int, height: int, map_seed: int,
# 		offset_x: int = 0, offset_y: int = 0) -> HeightMap:
#
# 	var noise := _create_noise(map_seed)
# 	var map := HeightMap.new(width, height)
#
# 	# 全局连续采样：每个瓦片读取其全局坐标对应的噪声值
# 	for y in height:
# 		for x in width:
# 			var val := noise.get_noise_2d(offset_x + x, offset_y + y)
# 			map.set_height(x, y, val * height_scale + height_offset)
#
# 	return map
#
# # ========================== 噪声工具模块 ==========================
# ## 根据当前参数创建配置好的 FastNoiseLite 实例
# ## 参数：map_seed (int) - 随机种子
# ## 返回值：FastNoiseLite - 配置好的噪声实例
# func _create_noise(map_seed: int) -> FastNoiseLite:
# 	var noise := FastNoiseLite.new()
# 	noise.noise_type = noise_type as FastNoiseLite.NoiseType
# 	noise.frequency = frequency
# 	noise.fractal_type = fractal_type as FastNoiseLite.FractalType
# 	noise.fractal_octaves = fractal_octaves
# 	noise.fractal_lacunarity = lacunarity
# 	noise.fractal_gain = gain
# 	noise.seed = map_seed
# 	return noise

# ==============================================================================
#   biome_map.gd
#   功能：将全局区块坐标映射到生态（BiomeConfig）。
#        使用低频噪声产生平滑、连续的生态过渡。
#   用法：创建 BiomeMap 实例，通过 add_biome() 按阈值注册生态，
#        然后传入 TerrainGenerator.biome_map。
# ==============================================================================
# [重构注释] 2.5D等距地图相关代码已暂时禁用
# extends RefCounted
# class_name BiomeMap
#
# # ========================== 变量定义模块 ==========================
# ## 噪声实例，用于生态分布
# var _noise: FastNoiseLite
#
# ## 阈值数组（升序），对应 _biomes
# var _thresholds: Array[float] = []
#
# ## 生态配置数组，_thresholds[i] 以下对应 _biomes[i]
# var _biomes: Array[BiomeConfig] = []
#
# # ========================== 生命周期模块 ==========================
# ## 功能：初始化噪声实例
# func _init() -> void:
# 	_noise = FastNoiseLite.new()
# 	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
# 	_noise.frequency = 0.003
# 	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
# 	_noise.fractal_octaves = 2
#
# # ========================== 公共 API 模块 ==========================
# ## 注册一个生态。threshold 在此值以下时返回该生态（值域 -1~1）。
# ## 靠前的生态应设置较低的 threshold，依次递增。
# ## 例如：海洋(-0.4), 沙滩(-0.15), 草地(0.15), 森林(0.5), 雪地(1.0)
# func add_biome(threshold: float, biome: BiomeConfig) -> void:
# 	_thresholds.append(threshold)
# 	_biomes.append(biome)
#
# ## 获取指定区块坐标对应的生态
# ## 参数：chunk_x (int) - 区块 X 坐标；chunk_y (int) - 区块 Y 坐标；world_seed (int) - 世界种子
# ## 返回值：BiomeConfig - 对应的生态配置
# func get_biome(chunk_x: int, chunk_y: int, world_seed: int) -> BiomeConfig:
# 	_noise.seed = world_seed
# 	var val := _noise.get_noise_2d(chunk_x, chunk_y)
#
# 	for i in _thresholds.size():
# 		if val < _thresholds[i]:
# 			return _biomes[i]
#
# 	# 超出所有阈值时返回最后一个
# 	return _biomes[-1]
#
# ## 设置噪声频率（值越小，生态区域越大）
# ## 参数：freq (float) - 频率值
# func set_frequency(freq: float) -> void:
# 	_noise.frequency = freq
#
# ## 设置分形噪声层数（值越大，生态边界越复杂）
# ## 参数：octaves (int) - 分形层数
# func set_octaves(octaves: int) -> void:
# 	_noise.fractal_octaves = octaves

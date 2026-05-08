extends Node2D
class_name GameWorld

@onready var chunk_manager: ChunkManager = $ChunkManager

# 加载生态配置（在 resources/data/biomes/ 目录下创建更多 .tres 即可扩展）
const BIOME_GRASSLAND := preload("res://resources/data/biomes/biome_grassland.tres") as BiomeConfig
const BIOME_DESERT := preload("res://resources/data/biomes/biome_desert.tres") as BiomeConfig
const BIOME_FOREST := preload("res://resources/data/biomes/biome_forest.tres") as BiomeConfig

func _ready() -> void:
	# 1. 构建生态分布图
	#    threshold：噪声值低于此值时归为该生态（噪声值域 -1~1）
	#    调整 set_frequency() 控制生态区域的大小：
	#      值越小 -> 单块生态区域越大（0.003 ≈ 每 330 区块完成一个周期）
	#      值越大 -> 生态变化越频繁
	var biome_map := BiomeMap.new()
	biome_map.set_frequency(0.003)
	biome_map.add_biome(-0.2, BIOME_DESERT)     # 噪声 < -0.2 -> 沙漠
	biome_map.add_biome(0.3, BIOME_GRASSLAND)   # -0.2 ≤ 噪声 < 0.3 -> 草地
	biome_map.add_biome(1.0, BIOME_FOREST)      # 0.3 ≤ 噪声 -> 森林

	# 2. 创建生成器并注入 BiomeMap
	var generator := TerrainGenerator.new()
	generator.biome_map = biome_map
	chunk_manager.generator = generator

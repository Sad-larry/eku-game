# ==============================================================================
#   ring_biome_entry.gd
#   功能：定义 ring 值与生态（BiomeConfig）的映射关系。
#         在 RadialGridConfig.ring_biomes 中使用。
# ==============================================================================
extends Resource
class_name RingBiomeEntry

## 圈层索引（0=起点，1~N=向外扩散的圈）
@export var ring_index: int = 0

## 该圈层对应的生态配置
@export var biome: BiomeConfig

# ==============================================================================
#   RadialGridConfig.gd
#   功能：菱形网格地图的全局配置参数
#         在编辑器中创建 .tres 实例以使用，用于控制圈层房间生成规则、事件权重等
# ==============================================================================
extends Resource
class_name RadialGridConfig

# ========================== 导出变量模块 ==========================
## 最大圈层数（0 为起点，1~N 为向外扩散的圈）
@export var max_ring: int = 4
## 随机种子（0 表示使用系统随机）
@export var world_seed: int = 0
## 每个房间对应的瓦片区块边长（单位：瓦片）
@export var chunk_size: int = 48
## 用于地形生成的 TileSet 引用
@export var tile_set: TileSet
## 每圈的事件权重表（按圈层索引映射）
@export var ring_event_pools: Array[RingEventPool]
## 保证在某些圈层固定出现的事件（Boss、商店等）
@export var guaranteed_events: Array[GuaranteedEventInfo]
## ring→生态映射表。设置后该 ring 的区块使用指定生态的瓦片集和地形规则。
## 未设置的 ring 使用 default_biome。
@export var ring_biomes: Array[RingBiomeEntry] = []
## 默认生态（当 ring 未在 ring_biomes 中设置时使用此生态）
@export var default_biome: BiomeConfig

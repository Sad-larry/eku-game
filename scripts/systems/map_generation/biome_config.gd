# ==============================================================================
#   biome_config.gd
#   功能：定义单个生态（Biome）的数据配置，包括瓦片调色板、水域生成参数等。
#        通过 .tres 文件实例化，可在编辑器中轻松创建和调整。
#   用法：在资源面板中右键 -> 新建资源 -> BiomeConfig，然后配置各属性。
# ==============================================================================
extends Resource
class_name BiomeConfig

## 生态名称（仅用于显示/调试）
@export var biome_name: String = ""

## TileSet 图集源 ID
@export var source_id: int = 1

# ========================== 基础地形瓦片 ==========================
## 基础地形瓦片调色板（满铺用）
@export var ground_palette: Array[Vector2i] = []

## 完整地面瓦在图集第 0 行的索引（无水相邻时的满铺瓦片）
@export var ground_full_index: int = 4

## 地面→水域的过渡瓦片（4 个方向，位置对应 DIR_ORDER）
@export var ground_transition: Array[Vector2i] = []

# ========================== 水域瓦片 ==========================
## 水域瓦片调色板
@export var water_palette: Array[Vector2i] = []

## 完整水域瓦在图集第 1 行的索引（无草地相邻时的满铺瓦片）
@export var water_full_index: int = 4

## 水域→地面的过渡瓦片（4 个方向，位置对应 DIR_ORDER）
@export var water_transition: Array[Vector2i] = []

# ========================== 生成参数 ==========================
## 每个区块产生水池的概率 [0.0, 1.0]
@export var water_density: float = 0.35

## 每个水池的瓦片数量范围
@export var water_body_size_min: int = 5
@export var water_body_size_max: int = 15

## BFS 扩展边界，水池允许超出区块边界多少格
@export var bfs_padding: int = 5

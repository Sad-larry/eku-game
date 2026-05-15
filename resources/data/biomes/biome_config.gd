# ==============================================================================
#   biome_config.gd
#   功能：定义单个生态（Biome）的数据配置。
#         移除 BFS 水域参数后，仅保留名称和图集源 ID，
#         每个生态通过 source_id 指向不同的 TileSet 图集。
#   用法：在资源面板中右键 -> 新建资源 -> BiomeConfig，然后配置各属性。
# ==============================================================================
extends Resource
class_name BiomeConfig

## 生态名称（仅用于显示/调试）
@export var biome_name: String = ""

## TileSet 图集源 ID
@export var source_id: int = 1

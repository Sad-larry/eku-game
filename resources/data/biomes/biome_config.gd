# ==============================================================================
#   biome_config.gd
#   功能：定义单个生态（Biome）的数据配置。
#         移除 BFS 水域参数后，仅保留名称和图集源 ID，
#         每个生态通过 source_id 指向不同的 TileSet 图集。
#   用法：在资源面板中右键 -> 新建资源 -> BiomeConfig，然后配置各属性。
# ==============================================================================
# [重构注释] 2.5D等距地图相关代码已暂时禁用
# extends Resource
# class_name BiomeConfig
#
# # ========================== 导出变量模块 ==========================
# ## 生态名称（仅用于显示/调试）
# @export var biome_name: String = ""
#
# ## TileSet 图集源 ID
# @export var source_id: int = 1
#
# ## 可选：覆盖全局的 TerrainHeightRules。
# ## 若不设置则回退到 TerrainGenerator 的全局 height_rules。
# @export var height_rules: TerrainHeightRules
#
# ## 噪声高度偏移量。查表前将高度值加上此偏移，整体抬升/压低生态的地形分布。
# ## 正数 → 更多高地形（石地/山地/雪地），负数 → 更多低地形（水域/沙地/泥地），
# ## 0.0 → 使用基准阈值（草地占主体）。
# ## 建议范围 [-0.5, 0.5]，相邻 ring 之间的 bias 差值不超过 0.15 以保过渡自然。
# @export var height_bias: float = 0.0
#
# # ========================== S7 地形效果扩展 ==========================
# ## 该生态对玩家/敌人施加的状态效果列表（如水面减速、火山灼烧）
# @export var terrain_effects: Array[Resource] = []
# ## 地形效果施加间隔（秒）
# @export var terrain_effect_interval: float = 2.0
# ## 环境装饰物场景列表
# @export var decoration_scenes: Array[PackedScene] = []
# ## 装饰物密度（0.0-1.0，每区块的期望数量比例）
# @export var decoration_density: float = 0.1
# ## 环境粒子效果
# @export var ambient_particles: PackedScene
# ## 环境音效
# @export var ambient_sound: AudioStream

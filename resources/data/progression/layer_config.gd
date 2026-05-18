# ==============================================================================
#   layer_config.gd
#   功能：层级配置资源，定义单层的难度参数、事件权重、Boss 配置等。
#        由 LayerProgressionConfig 管理，RunManager 根据当前层数查询使用。
# ==============================================================================
extends Resource
class_name LayerConfig

# ========================== 导出变量模块 ==========================
## 层索引（从 1 开始）
@export var layer_index: int = 1

## 该层菱形网格的半径（max_ring），决定地图大小
@export var max_ring: int = 4

## 敌人血量倍率（基础值 × 该倍率）
@export var enemy_health_multiplier: float = 1.0

## 敌人伤害倍率（基础值 × 该倍率）
@export var enemy_damage_multiplier: float = 1.0

## 掉落金币倍率
@export var coin_multiplier: float = 1.0

## 精英出现概率加成（叠加到基础概率上）
@export var elite_chance_bonus: float = 0.0

## 该层的 Boss 配置（为 null 时使用默认敌人配置）
@export var boss_config: Resource = null

## 覆盖默认事件权重池（为空时使用 RadialGridConfig 的默认池）
@export var ring_event_overrides: Array[Resource] = []

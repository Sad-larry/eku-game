# ==============================================================================
#   elite_modifier.gd
#   功能：精英强化配置资源。定义精英敌人的属性倍率和特殊能力。
# ==============================================================================
class_name EliteModifier extends Resource

# ========================== 属性强化模块 ==========================
## 生命值倍率（如 2.0 表示生命值翻倍）
@export var health_multiplier: float = 2.0
## 伤害倍率
@export var damage_multiplier: float = 1.5
## 体积缩放系数（大于 1.0 放大，小于 1.0 缩小）
@export var size_scale: float = 1.3
## 精英外观染色（覆盖精灵默认颜色）
@export var visual_tint: Color = Color(1, 0.5, 0.5)

# ========================== 特殊能力模块 ==========================
## 精英光环效果（持续施加的状态效果类型）
@export var aura_effect: StatusEffectType
## 召唤物场景（精英可周期性召唤小怪）
@export var summon_scene: PackedScene
## 召唤间隔（秒）
@export var summon_interval: float = 10.0
## 额外护盾血量（独立于生命值的护盾）
@export var shield_hp: int = 0
## 附带的状态效果列表（受击时施加给玩家）
@export var bonus_status_effects: Array[StatusEffectType] = []

# ========================== 奖励模块 ==========================
## 击杀额外金币倍率
@export var coin_multiplier: float = 2.0

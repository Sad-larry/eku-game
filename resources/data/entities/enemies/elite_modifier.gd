# ==============================================================================
#   elite_modifier.gd
#   功能：精英强化配置资源。定义精英敌人的属性倍率和特殊能力。
# ==============================================================================
class_name EliteModifier extends Resource

@export var health_multiplier: float = 2.0
@export var damage_multiplier: float = 1.5
@export var size_scale: float = 1.3
@export var visual_tint: Color = Color(1, 0.5, 0.5)
@export var aura_effect: StatusEffectType
@export var summon_scene: PackedScene
@export var summon_interval: float = 10.0
@export var shield_hp: int = 0
@export var bonus_status_effects: Array[StatusEffectType] = []
## 击杀额外金币倍率
@export var coin_multiplier: float = 2.0

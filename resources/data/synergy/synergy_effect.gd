# ==============================================================================
#   synergy_effect.gd
#   功能：协同效果资源类，定义协同触发时的效果类型和参数。
# ==============================================================================
extends Resource
class_name SynergyEffect

## 效果类型枚举
enum EffectType {
	## 伤害加成
	DAMAGE_BONUS,
	## 施加状态效果
	APPLY_STATUS,
	## 生成投射物
	SPAWN_PROJECTILE,
	## 治疗
	HEAL,
	## 范围效果
	AREA_EFFECT
}

## 效果类型
@export var effect_type: EffectType = EffectType.DAMAGE_BONUS
## 伤害加成倍率（仅DAMAGE_BONUS类型）
@export var damage_multiplier: float = 1.5
## 施加的状态效果（仅APPLY_STATUS类型）
@export var status_effect: StatusEffectType
## 状态效果持续时间
@export var status_duration: float = 0.0
## 生成的投射物场景（仅SPAWN_PROJECTILE类型）
@export var projectile_scene: PackedScene
## AOE范围（仅AREA_EFFECT类型）
@export var area_radius: float = 0.0
## 治疗量（仅HEAL类型）
@export var heal_amount: float = 0.0
## 视觉特效
@export var visual_effect: PackedScene

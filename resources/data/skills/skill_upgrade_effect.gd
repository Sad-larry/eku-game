# ==============================================================================
#   skill_upgrade_effect.gd
#   功能：定义单级技能升级效果，作为 SkillUpgradeData 的子资源使用。
# ==============================================================================
extends Resource
class_name SkillUpgradeEffect

@export var damage_multiplier_bonus: float = 0.0
@export var cooldown_reduction: float = 0.0
@export var energy_cost_reduction: int = 0

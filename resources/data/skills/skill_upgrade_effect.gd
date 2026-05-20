# ==============================================================================
#   skill_upgrade_effect.gd
#   功能：定义单级技能升级效果，作为 SkillUpgradeData 的子资源使用。
# ==============================================================================
extends Resource
class_name SkillUpgradeEffect

# ========================== 属性加成模块 ==========================
## 伤害倍率加成（如 0.2 = 伤害 +20%）
@export var damage_multiplier_bonus: float = 0.0
## 冷却时间缩减（秒）
@export var cooldown_reduction: float = 0.0
## 能量消耗减免
@export var energy_cost_reduction: int = 0

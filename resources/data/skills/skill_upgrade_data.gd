# ==============================================================================
#   skill_upgrade_data.gd
#   功能：定义技能升级配置，包含最大等级、费用曲线和逐级效果。
#        upgrade_costs 与 level_effects 为平行数组，长度 = max_level - 1。
#        index 0 表示 Lv1→Lv2 的费用/效果。
# ==============================================================================
extends Resource
class_name SkillUpgradeData

@export var skill_id: String = ""
@export var max_level: int = 5
@export var upgrade_costs: Array[int] = []
@export var level_effects: Array[Resource] = []  # Array[SkillUpgradeEffect]

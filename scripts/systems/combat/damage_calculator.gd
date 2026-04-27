extends Node
class_name DamageCalculator

## 伤害计算公式：最终伤害 = 基础伤害 × 技能倍率 × 暴击修正 × 随机浮动
func calculate(base_damage: float, skill_multiplier: float, crit_rate: float, crit_damage: float) -> Dictionary:
	"""
	伤害计算函数
	:param base_damage: 基础伤害
	:param skill_multiplier: 技能倍率
	:param crit_rate: 暴击率(0~1)
	:param crit_damage: 暴击伤害倍率
	:return: 包含暴击状态和最终伤害的结果对象
	"""
	# 判断是否暴击
	var is_crit = Global.get_chance_success(crit_rate)
	# 暴击修正
	var crit_correction = base_damage * crit_damage if is_crit else base_damage
	# 代入伤害公式计算最终伤害
	var final_damage = skill_multiplier * crit_correction
	return {"damage": final_damage, "is_crit": is_crit}

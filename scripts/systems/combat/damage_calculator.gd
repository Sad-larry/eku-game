# ==============================================================================
#   damage_calculator.gd
#   功能：伤害计算工具类，提供统一的伤害公式计算逻辑（含暴击判定、技能倍率、
#        随机浮动等），可作为静态工具直接调用。
# ==============================================================================
extends RefCounted
class_name DamageCalculator

# ========================== 公共静态方法模块 ==========================
## 功能：根据基础伤害、技能倍率、暴击率、暴击伤害计算最终伤害
## 参数：
##   base_damage (float) - 基础伤害值
##   skill_multiplier (float) - 技能倍率（如 1.5 表示 150% 伤害）
##   crit_rate (float) - 暴击率，范围 0.0 - 1.0
##   crit_damage (float) - 暴击伤害倍率（如 2.0 表示 200% 伤害）
## 返回值：Dictionary - 包含 "damage"（最终伤害）和 "is_crit"（是否暴击）
## 示例：calculate(100.0, 1.5, 0.3, 2.0) 返回 {"damage": 150.0, "is_crit": false} 或暴击时 damage 为 300.0
func calculate(base_damage: float, skill_multiplier: float, crit_rate: float, crit_damage: float) -> Dictionary:
	# 判断是否触发暴击
	# 注意：Global.get_chance_success 是静态函数，必须通过类型名调用，而非实例
	var is_crit = Global.get_chance_success(crit_rate)

	# 计算暴击修正后的基准伤害
	# 若暴击，基准伤害乘以暴击倍率；否则保持不变
	var crit_correction = base_damage * crit_damage if is_crit else base_damage

	# 代入完整伤害公式：技能倍率 × 暴击修正后的基准伤害
	var final_damage = skill_multiplier * crit_correction

	# 返回结果字典（伤害值保留两位小数，可选）
	return {"damage": final_damage, "is_crit": is_crit}

## 功能：计算带有状态效果修正的最终伤害
## 参数：同 calculate()，额外传入 effect_multiplier（来自 StatusEffectComponent.get_damage_multiplier()）
## 返回值：Dictionary - 包含 "damage"（最终伤害）和 "is_crit"（是否暴击）
func calculate_with_effects(base_damage: float, skill_multiplier: float, crit_rate: float, crit_damage: float, effect_multiplier: float) -> Dictionary:
	var result := calculate(base_damage, skill_multiplier, crit_rate, crit_damage)
	result["damage"] = result["damage"] * effect_multiplier
	return result

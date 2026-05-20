# ==============================================================================
#   weapon_data.gd
#   功能：武器数据资源类，定义武器的所有属性。
# ==============================================================================
extends Resource
class_name WeaponData

## 武器类型枚举
enum WeaponType {
	## 剑（近战均衡）
	SWORD,
	## 弓（远程攻击）
	BOW,
	## 法杖（魔法攻击）
	STAFF,
	## 盾（防御为主）
	SHIELD
}

## 武器唯一标识符
@export var id: String = ""
## 武器显示名称
@export var display_name: String = ""
## 武器描述
@export var description: String = ""
## 武器图标
@export var icon: Texture2D
## 武器类型
@export var weapon_type: WeaponType = WeaponType.SWORD
# ========================== 基础属性 ==========================
## 基础伤害
@export var base_damage: float = 10.0
## 攻击速度（次/秒）
@export var attack_speed: float = 1.0
## 暴击率（0.0-1.0）
@export var crit_rate: float = 0.05
## 暴击伤害倍率
@export var crit_damage: float = 1.5
## 攻击范围
@export var attack_range: float = 50.0
# ========================== 武器技能 ==========================
## 武器专属技能
@export var weapon_skill: SkillEffect
## 武器技能冷却时间（秒）
@export var weapon_skill_cooldown: float = 10.0
# ========================== 协同标签 ==========================
## 武器标签（用于协同系统匹配）
@export var tags: Array[String] = []
# ========================== 升级配置 ==========================
## 最大等级
@export var max_level: int = 10
## 升级费用列表（索引对应等级-1）
@export var upgrade_costs: Array[int] = []
## 每级伤害倍率列表（索引对应等级-1）
@export var level_multipliers: Array[float] = []
# ========================== 附魔配置 ==========================
## 最大附魔槽位
@export var max_enchant_slots: int = 2
# ========================== 视觉效果 ==========================
## 武器攻击动画基础名称
@export var anim_base_name: String = ""
## 武器攻击特效场景
@export var attack_effect: PackedScene

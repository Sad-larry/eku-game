# ==============================================================================
#   weapon_enchant.gd
#   功能：武器附魔资源类，定义附魔效果。
# ==============================================================================
extends Resource
class_name WeaponEnchant

## 附魔唯一标识符
@export var id: String = ""
## 附魔显示名称
@export var display_name: String = ""
## 附魔描述
@export var description: String = ""
## 附魔图标
@export var icon: Texture2D
# ========================== 附魔效果 ==========================
## 伤害加成
@export var damage_bonus: float = 0.0
## 暴击率加成
@export var crit_rate_bonus: float = 0.0
## 暴击伤害加成
@export var crit_damage_bonus: float = 0.0
## 攻击速度加成
@export var attack_speed_bonus: float = 0.0
## 附加元素标签
@export var element_tag: String = ""
## 攻击时施加的状态效果
@export var status_effect: StatusEffectType
## 状态效果触发概率（0.0-1.0）
@export var status_chance: float = 0.0
## 状态效果持续时间
@export var status_duration: float = 0.0
# ========================== 协同标签 ==========================
## 附魔标签（用于协同系统匹配）
@export var tags: Array[String] = []
# ========================== 特殊效果 ==========================
## 生命偷取比例（0.0-1.0）
@export var lifesteal_ratio: float = 0.0
## 伤害吸收护盾（每次攻击生成）
@export var shield_per_hit: float = 0.0
## AOE伤害范围（0=无AOE）
@export var aoe_radius: float = 0.0
## AOE伤害比例（相对于主伤害）
@export var aoe_damage_ratio: float = 0.5

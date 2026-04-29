# ==============================================================================
#   DamageData.gd
#   功能：伤害数据资源类，封装一次伤害事件所需的所有参数（伤害值、暴击属性、
#        源目标、技能信息等），用于在战斗系统的各组件间传递伤害信息。
# ==============================================================================
extends Resource
class_name DamageData

# ========================== 导出变量模块 ==========================
## 伤害数值（最终结算前的原始伤害值）
@export var value: int

## 暴击率（0.0 - 1.0），判定本次伤害是否触发暴击的概率
@export var crit_rate: float

## 暴击伤害倍率（如 2.0 表示 200% 暴击伤害）
@export var crit_damage: float

## 伤害来源方节点路径（攻击者）
@export var source: NodePath

## 伤害承受方节点路径（受击者）
@export var target: NodePath

## 触发本次伤害的技能效果资源
@export var skill: SkillEffect

## 技能倍率（技能自身的伤害放大系数，如 1.5 表示 150%）
@export var skill_multiplier: float

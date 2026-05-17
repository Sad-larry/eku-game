# ==============================================================================
#   DamageInfo.gd
#   功能：伤害数据包装对象，在技能系统各组件间传递伤害信息。
#        替代原有的 Dictionary 传参，提供类型安全的接口。
# ==============================================================================
extends RefCounted
class_name DamageInfo

# ========================== 变量定义模块 ==========================
## 最终伤害值（已含暴击/倍率计算）
var final_damage: float = 0.0

## 是否暴击
var is_crit: bool = false

## 伤害来源（玩家/敌人）
var source: Node2D

## 伤害目标
var target: Node2D

## 关联的技能数据
var skill_data: SkillEffect

# ==============================================================================
#   synergy_rule.gd
#   功能：协同规则资源类，定义技能协同的触发条件和效果。
# ==============================================================================
extends Resource
class_name SynergyRule

## 规则唯一标识符
@export var id: String = ""
## 规则显示名称
@export var display_name: String = ""
## 规则描述
@export var description: String = ""
## 触发条件：敌人身上的状态效果tags
@export var required_debuff_tags: Array[String] = []
## 触发技能的tags要求
@export var trigger_skill_tags: Array[String] = []
## 协同效果
@export var synergy_effect: SynergyEffect
## 触发概率（1.0 = 必定触发）
@export var trigger_chance: float = 1.0
## 冷却时间（秒）
@export var cooldown: float = 0.0
## 每次运行最多触发次数（0=无限制）
@export var max_triggers_per_run: int = 0

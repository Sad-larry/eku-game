# ==============================================================================
#   boss_skill_drop.gd
#   功能：BOSS技能掉落配置资源类，定义BOSS的专属技能掉落规则。
# ==============================================================================
extends Resource
class_name BossSkillDrop

## BOSS唯一标识符
@export var boss_id: String = ""
## 可掉落的技能列表
@export var drop_skills: Array[SkillEffect] = []
## 首次击败是否必定掉落
@export var first_clear_guaranteed: bool = true
## 重复击败的掉落概率（0.0-1.0）
@export var repeat_drop_chance: float = 0.3
## 每次掉落数量
@export var drop_count: int = 1
## 掉落技能的解锁方式（true=直接解锁，false=进入技能选择池）
@export var direct_unlock: bool = true

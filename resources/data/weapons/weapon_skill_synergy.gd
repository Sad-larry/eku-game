# ==============================================================================
#   weapon_skill_synergy.gd
#   功能：武器技能协同资源类，定义特定武器+技能组合的隐藏效果。
# ==============================================================================
extends Resource
class_name WeaponSkillSynergy

## 协同唯一标识符
@export var id: String = ""
## 协同显示名称
@export var display_name: String = ""
## 协同描述
@export var description: String = ""
# ========================== 触发条件 ==========================
## 武器需要的tags（全部满足才触发）
@export var required_weapon_tags: Array[String] = []
## 技能需要的tags（全部满足才触发）
@export var required_skill_tags: Array[String] = []
# ========================== 效果 ==========================
## 伤害加成倍率
@export var damage_multiplier: float = 1.5
## 额外协同效果
@export var bonus_effect: SynergyEffect
## 视觉特效场景
@export var visual_effect: PackedScene
# ========================== 触发限制 ==========================
## 触发概率（1.0 = 必定触发）
@export var trigger_chance: float = 1.0
## 冷却时间（秒）
@export var cooldown: float = 0.0
## 每次运行最多触发次数（0=无限制）
@export var max_triggers_per_run: int = 0

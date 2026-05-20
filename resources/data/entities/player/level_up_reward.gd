# ==============================================================================
#   level_up_reward.gd
#   功能：定义单级玩家升级奖励，作为 PlayerProgression 的子资源使用。
# ==============================================================================
extends Resource
class_name LevelUpReward

# ========================== 属性加成模块 ==========================
## 最大生命值加成
@export var max_health_bonus: int = 0
## 基础伤害加成
@export var damage_bonus: int = 0
## 移动速度加成
@export var speed_bonus: float = 0.0
## 暴击率加成（0.0 - 1.0）
@export var crit_rate_bonus: float = 0.0
## 暴击伤害倍率加成（如 0.5 表示暴击伤害 +50%）
@export var crit_damage_bonus: float = 0.0

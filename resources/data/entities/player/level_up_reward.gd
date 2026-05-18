# ==============================================================================
#   level_up_reward.gd
#   功能：定义单级玩家升级奖励，作为 PlayerProgression 的子资源使用。
# ==============================================================================
extends Resource
class_name LevelUpReward

@export var max_health_bonus: int = 0
@export var damage_bonus: int = 0
@export var speed_bonus: float = 0.0
@export var crit_rate_bonus: float = 0.0
@export var crit_damage_bonus: float = 0.0

# ==============================================================================
#   player_progression.gd
#   功能：定义玩家成长配置，包含最大等级、升级费用曲线和逐级奖励。
#        level_up_costs 与 level_rewards 为平行数组，长度 = max_level - 1。
#        index 0 表示 Lv1→Lv2 的费用/奖励。
# ==============================================================================
extends Resource
class_name PlayerProgression

# ========================== 等级配置模块 ==========================
## 玩家最大等级
@export var max_level: int = 10
## 逐级升级费用（长度 = max_level - 1，index 0 = Lv1→Lv2 的费用）
@export var level_up_costs: Array[int] = []
## 逐级升级奖励（长度 = max_level - 1，index 0 = Lv1→Lv2 的奖励）
@export var level_rewards: Array[Resource] = []  # Array[LevelUpReward]

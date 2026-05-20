# ==============================================================================
#   achievement_data.gd
#   功能：成就数据资源类，定义成就的解锁条件和奖励。
# ==============================================================================
extends Resource
class_name AchievementData

## 成就类型枚举
enum AchievementType {
	## 统计型（累计数值达到阈值）
	STAT,
	## 事件型（触发特定事件）
	EVENT,
	## 收集型（收集特定数量的物品）
	COLLECTION,
	## 特殊型（特殊条件）
	SPECIAL
}

## 条件类型枚举
enum ConditionType {
	KILL_COUNT,      ## 击杀计数
	BOSS_DEFEAT,     ## BOSS 击败
	LAYER_REACH,     ## 层级到达
	SYNERGY_COUNT,   ## 协同触发计数
	WEAPON_UPGRADE,  ## 武器升级
	RELIC_COUNT,     ## 遗物收集计数
}

## 成就唯一标识符
@export var id: String = ""
## 成就显示名称
@export var display_name: String = ""
## 成就描述
@export var description: String = ""
## 成就图标
@export var icon: Texture2D
## 成就类型
@export var achievement_type: AchievementType = AchievementType.STAT

# ========================== 解锁条件 ==========================
## 条件类型
@export var condition_type: ConditionType = ConditionType.KILL_COUNT
## 条件目标值
@export var condition_value: int = 0
## 条件目标 ID（敌人类型、BOSS ID、技能 ID 等，为空则不限定）
@export var condition_target: String = ""

# ========================== 奖励 ==========================
## 奖励金币数量
@export var reward_coins: int = 0
## 奖励遗物（为 null 则无遗物奖励）
@export var reward_relic: Resource = null
## 奖励技能（为 null 则无技能奖励）
@export var reward_skill: Resource = null

# ========================== 显示 ==========================
## 是否为隐藏成就（未解锁前不显示详情）
@export var is_hidden: bool = false
## 成就排序优先级（数值越小越靠前）
@export var sort_order: int = 0

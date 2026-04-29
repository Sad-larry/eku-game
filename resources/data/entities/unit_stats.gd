# ==============================================================================
#   UnitStats.gd
#   功能：单位属性资源类，定义游戏中所有战斗单位（玩家、敌人）的基础属性模板。
#        包含生命值、能量值、攻击力、暴击率等数值，可用于初始化角色或敌人。
# ==============================================================================
extends Resource
class_name UnitStats

# ========================== 枚举定义模块 ==========================
## 单位类型枚举
enum UnitType {
	PLAYER,   ## 玩家单位
	ENEMY     ## 敌人单位
}

# ========================== 导出变量模块 ==========================
# ----- 基础信息 -----
## 单位显示名称
@export var name: String

## 单位类型（玩家/敌人）
@export var type: UnitType

## 单位图标（用于 UI 显示）
@export var icon: Texture2D

# ----- 移动属性 -----
## 移动速度（像素/秒）
@export var speed := 100

# ----- 生命值属性 -----
## 最大生命值
@export var max_health := 1

# ----- 能量值属性 -----
## 最大能量值
@export var max_energy := 1

## 每秒自动恢复能量值
@export var energy_regen: float = 1

# ----- 战斗属性 -----
## 基础攻击伤害值
@export var base_attack_damage := 1

## 攻击速度（每秒攻击次数）
@export var attack_speed: float = 1.0

## 暴击率（0.0 - 1.0），默认 5%
@export var crit_rate: float = 0.05

## 暴击伤害倍率（如 1.5 表示 150% 暴击伤害），默认 150%
@export var crit_damage: float = 1.5

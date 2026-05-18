# ==============================================================================
#   enemy_stats.gd
#   功能：单位属性资源类，定义游戏中敌人单位的基础属性模板。
# ==============================================================================
extends UnitStats
class_name EnemyStats

# ========================== 导出变量模块 ==========================
## 经验值
@export var experience_value: int = 10

# ----- 战斗属性 -----
## 检测范围（像素），玩家进入此范围敌人开始追击
@export var detection_range: float = 200.0

## 攻击范围（像素），玩家进入此范围敌人开始攻击
@export var attack_range: float = 30.0

## 攻击冷却时间（秒）
@export var attack_cooldown: float = 1.5

## 暴击率（0.0 ~ 1.0）
@export var crit_rate: float = 0.0

## 暴击伤害倍率
@export var crit_damage: float = 2.0

## 受击硬直时间（秒）
@export var hurt_duration: float = 0.3

# ----- 游走行为 -----
## 游走范围（像素），从生成位置算起的随机游走半径
@export var wander_range: float = 80.0

## 游走等待时间范围（秒），每次游走之间停留的时间范围 [min, max]
@export var wander_pause_range: Vector2 = Vector2(1.0, 3.0)

## 游走移动持续时间范围（秒），每次游走移动的时长范围 [min, max]
@export var wander_move_range: Vector2 = Vector2(0.5, 2.0)

# ----- 视觉表现 -----
## 是否有武器
@export var has_weapon: bool = false

## 武器图标
@export var weapon_texture: Texture2D

# ----- 行为标签 -----
## ["melee", "ranged", "elite", "flying"]
@export var tags: Array[String] = []   

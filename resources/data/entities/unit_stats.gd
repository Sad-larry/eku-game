# ==============================================================================
#   unit_stats.gd
#   功能：单位属性资源基类，定义游戏中单位的基础属性模板。
# ==============================================================================
extends Resource
class_name UnitStats

# ========================== 导出变量模块 ==========================
# ----- 基础属性 -----
## 单位显示名称
@export var name: String

## 单位图标（用于 UI 显示）
@export var icon: Texture2D

## 最大生命值
@export var max_health: int = 30

## 移动速度（像素/秒）
@export var speed : float = 100.0

## 攻击伤害值
@export var damage: int = 1

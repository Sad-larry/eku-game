# ==============================================================================
#   boss_config.gd
#   功能：Boss 配置资源，定义 Boss 的场景、名称、阶段、奖励等参数。
#        由 LayerConfig 引用，GameWorld 在生成 Boss 房间时使用。
# ==============================================================================
extends Resource
class_name BossConfig

# ========================== 导出变量模块 ==========================
## Boss 实体场景
@export var boss_scene: PackedScene

## Boss 名称（用于 UI 显示）
@export var boss_name: String = ""

## Boss 阶段数
@export var phases: int = 1

## 阶段切换血量阈值（数组长度 = phases - 1）
## 例如 [0.5] 表示血量降到 50% 时切换到第二阶段
@export var phase_health_thresholds: Array[float] = [0.5]

## Boss 竞技场半径（像素）
@export var arena_size: float = 300.0

## 击败奖励金币
@export var reward_coins: int = 100

## 击败后是否解锁下一层
@export var unlock_next_layer: bool = true

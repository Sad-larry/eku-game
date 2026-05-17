# ==============================================================================
#   enemy_movement_component.gd
#   功能：敌人移动组件，负责处理敌人的移动速度计算、加速度/减速度平滑、以及
#        速度的即时停止。通过修改宿主 Enemy 的 velocity 属性实现移动。
# ==============================================================================
extends Node
class_name EnemyMovementComponent

# ========================== 导出变量模块 ==========================
## 加速度（像素/秒²），控制速度提升的平滑度
@export var acceleration: float = 800.0
## 减速度（像素/秒²），控制速度下降的平滑度（停止时生效）
@export var deceleration: float = 600.0

# ========================== 内部变量模块 ==========================
## 当前内部速度向量（用于平滑过渡）
var _velocity: Vector2 = Vector2.ZERO
## 宿主敌人实例引用（通过 owner 获取）
var _enemy: Enemy

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时获取宿主 Enemy 引用
func _ready() -> void:
	_enemy = owner as Enemy

# ========================== 公共 API 模块 ==========================
## 功能：向指定方向移动（带加速度平滑）
## 参数：direction (Vector2) - 标准化移动方向；delta (float) - 物理帧间隔时间
func move_toward(direction: Vector2, delta: float) -> void:
	var target_velocity: Vector2 = direction * _enemy.get_speed()
	_velocity = _velocity.move_toward(target_velocity, acceleration * delta)
	_enemy.velocity = _velocity

## 功能：立即停止移动（无减速度平滑，直接清零速度）
func stop_immediately() -> void:
	_velocity = Vector2.ZERO
	_enemy.velocity = Vector2.ZERO

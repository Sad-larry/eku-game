# ==============================================================================
#   player_movement_component.gd
#   功能：玩家移动组件，将输入方向转为 8 方向速度并应用到父节点。
# ==============================================================================
extends Node
class_name PlayerMovementComponent

# ========================== 变量定义模块 ==========================
## 移动速度（像素/秒）
var _speed: float = 100.0

## 当前运动方向（8 方向标准化后的向量）
var current_direction: Vector2 = Vector2.ZERO

## 当前的即时速度向量
var current_velocity: Vector2 = Vector2.ZERO

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时验证父节点类型
func _ready() -> void:
	if not get_parent() is CharacterBody2D:
		push_error("PlayerMovementComponent: 父节点不是 CharacterBody2D！")

# ========================== 公共 API 模块 ==========================
## 功能：初始化移动组件，根据 UnitStats 资源设置移动速度
## 参数：stats (UnitStats) - 单位属性资源，需包含 speed 字段
func setup(stats: UnitStats) -> void:
	_speed = stats.speed

## 功能：计算移动速度并应用到父节点
## 参数：input_direction (Vector2) - 原始移动输入向量；delta (float) - 物理帧间隔时间（秒）
## 说明：将输入方向约束为 8 方向之一，乘以速度后直接设置父节点的 velocity
func update_movement(input_direction: Vector2, _delta: float) -> void:
	current_direction = DirectionUtils.normalize_8_direction(input_direction)
	current_velocity = current_direction * _speed

	get_parent().velocity = current_velocity

## 功能：立即停止移动（重置速度及相关状态）
## 说明：有时调用后玩家还有惯性是因为下一帧 physics_process 重新计算了速度，
##       调用此方法时应同时通过状态机的 is_movement_allowed() 阻止后续速度更新。
func stop_immediately() -> void:
	current_velocity = Vector2.ZERO
	current_direction = Vector2.ZERO

	get_parent().velocity = Vector2.ZERO

## 功能：设置移动速度覆盖值（用于传送减速等临时速度修改）
## 参数：speed (float) - 新的速度值（像素/秒）
func set_speed_override(speed: float) -> void:
	_speed = speed

## 功能：获取当前移动速度
## 返回值：float - 当前速度（像素/秒）
func get_current_speed() -> float:
	return _speed

## 功能：获取当前运动方向（8 方向标准化后）
## 返回值：Vector2 - 单位方向向量
func get_movement_direction() -> Vector2:
	return current_direction

## 功能：获取当前即时速度向量
## 返回值：Vector2 - 当前速度（像素/秒）
func get_current_velocity() -> Vector2:
	return current_velocity

## 功能：判断当前速度是否接近零
## 参数：tolerance (float) - 速度阈值（像素/秒），默认 5.0
## 返回值：bool - true 表示处于静止状态
func is_idle(tolerance: float = 5.0) -> bool:
	return current_velocity.length() < tolerance

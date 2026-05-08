# ==============================================================================
#   PlayerMovementComponent.gd
#   功能：玩家移动组件，管理角色的移动速度、8方向输入标准化、速度平滑（加速度/减速度），
#        并将最终速度应用到父节点（CharacterBody2D）的 velocity 属性。
# ==============================================================================
extends Node
class_name PlayerMovementComponent

# ========================== 导出变量模块 ==========================
## 移动速度（像素/秒）
@export var speed: float = 150.0

## 是否启用加速度（平滑移动），若不启用则速度瞬间变化
@export var use_acceleration: bool = false

## 加速度（像素/秒²），控制速度提升的平滑度
@export var acceleration: float = 1200.0

## 减速度（刹车/摩擦力，像素/秒²），控制速度下降的平滑度
@export var deceleration: float = 1800.0

# ========================== 变量定义模块 ==========================
## 当前运动方向（标准化后的向量）
var current_direction: Vector2 = Vector2.ZERO

## 当前的即时速度（用于物理更新）
var current_velocity: Vector2 = Vector2.ZERO

## 缓存父节点 CharacterBody2D 引用
var _parent: CharacterBody2D = null

# ========================== 常量定义模块 ==========================
## 8方向预设向量（顺序：右、右下、下、左下、左、左上、上、右上）
const EIGHT_DIRECTIONS: Array[Vector2] = [
	Vector2.RIGHT,          # 0°   -> 右
	Vector2(1, 1),          # 45°  -> 右下
	Vector2.DOWN,           # 90°  -> 下
	Vector2(1, -1),         # 315° -> 右上
	Vector2.LEFT,           # 180° -> 左
	Vector2(-1, -1),        # 225° -> 左上
	Vector2.UP,             # 270° -> 上
	Vector2(-1, 1)          # 135° -> 左下
]

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时获取父节点引用并验证类型
func _ready() -> void:
	_parent = get_parent()
	if not _parent is CharacterBody2D:
		push_error("MovementComponent: 父节点不是 CharacterBody2D！")
		queue_free()

# ========================== 公共 API 模块 ==========================
## 功能：每帧更新移动逻辑（应在 _physics_process 中调用）
## 参数：input_direction (Vector2) - 原始移动输入向量；delta (float) - 物理帧间隔时间（秒）
func update_movement(input_direction: Vector2, delta: float) -> void:
	if not _parent:
		return
	
	# 可选：将输入方向转换为等距坐标系下的8方向（当前注释，可直接使用原始输入）
	# var iso_dir := IsoMovement.map_input_to_iso(input_direction)
	# 将输入向量规范化为8方向向量
	current_direction = normalize_8_direction(input_direction)
	
	# 计算目标速度，需要进行归一化
	var target_velocity: Vector2 = current_direction.normalized() * speed
	
	if use_acceleration:
		# 平滑到达目标速度
		if current_direction == Vector2.ZERO:
			# 无输入时：使用减速度减速
			current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration * delta)
		else:
			# 有输入时：使用加速度加速
			current_velocity = current_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# 直接设置速度（无平滑）
		current_velocity = target_velocity
	
	# 应用到父节点的 velocity 属性
	_parent.velocity = current_velocity

## 功能：立即停止移动（重置速度及相关状态）
func stop_immediately() -> void:
	current_velocity = Vector2.ZERO
	current_direction = Vector2.ZERO
	if _parent:
		_parent.velocity = Vector2.ZERO

## 功能：获取当前运动方向（标准化后）
## 返回值：Vector2 - 单位方向向量
func get_movement_direction() -> Vector2:
	return current_direction

## 功能：获取当前即时速度向量
## 返回值：Vector2 - 当前速度（像素/秒）
func get_current_velocity() -> Vector2:
	return current_velocity

## 功能：判断当前速度是否接近零（可用于判断是否静止）
## 参数：tolerance (float) - 速度阈值（像素/秒），默认 5.0
## 返回值：bool - true 表示处于静止状态
func is_idle(tolerance: float = 5.0) -> bool:
	return current_velocity.length() < tolerance

# ========================== 静态工具方法模块 ==========================
## 功能：将任意向量映射到8个主方向之一（8方向标准化）
## 参数：dir (Vector2) - 原始输入向量（无需预先标准化）
## 返回值：Vector2 - 标准化后的8方向单位向量，若输入长度趋近于零则返回 Vector2.ZERO
static func normalize_8_direction(dir: Vector2) -> Vector2:
	if dir.length() < 0.01:
		return Vector2.ZERO
	
	var normalized = dir
	var angle = normalized.angle()
	
	# 找到最接近的预设方向
	var best_dir = EIGHT_DIRECTIONS[0]
	var min_diff = abs(angle_difference(angle, best_dir.angle()))
	
	for candidate in EIGHT_DIRECTIONS:
		# 使用内置角度差函数修复跨 ±π 边界计算问题
		var diff = abs(angle_difference(angle, candidate.angle()))
		if diff < min_diff:
			min_diff = diff
			best_dir = candidate
	
	return best_dir

## 功能：获取原始8方向枚举索引（用于其他系统）
## 参数：dir (Vector2) - 方向向量（建议已标准化）
## 返回值：int - 方向索引（0~7），若输入为零向量则返回 -1
static func get_eight_direction_enum(dir: Vector2) -> int:
	if dir.length() < 0.01:
		return -1
	var eight_dir = normalize_8_direction(dir)
	for i in range(EIGHT_DIRECTIONS.size()):
		if eight_dir == EIGHT_DIRECTIONS[i]:
			return i
	return -1

# movement_component.gd
# 移动组件：管理角色的移动速度、方向标准化、速度平滑
# 挂载到 CharacterBody2D 节点（或继承自该节点的角色）
class_name MovementComponent
extends Node

## 移动速度（单位：像素/秒）
@export var speed: float = 200.0
## 是否启用加速度（平滑移动）
@export var use_acceleration: bool = false
## 加速度（像素/秒²）
@export var acceleration: float = 1200.0
## 减速度（刹车/摩擦力，像素/秒²）
@export var deceleration: float = 1800.0

## 当前运动方向（标准化后的向量）
var current_direction: Vector2 = Vector2.ZERO
## 当前的即时速度（用于物理更新）
var current_velocity: Vector2 = Vector2.ZERO
# 缓存父节点 CharacterBody2D
var _parent: CharacterBody2D = null

## 8方向预设（右、右下、下、左下、左、左上、上、右上）
const EIGHT_DIRECTIONS: Array[Vector2] = [
	Vector2.RIGHT,          # 0°
	Vector2(1, 1),   # 45°（右下）
	Vector2.DOWN,           # 90°
	Vector2(1, -1),  # 135°（右上）
	Vector2.LEFT,           # 180°
	Vector2(-1, -1), # 225°（左上）
	Vector2.UP,             # 270°
	Vector2(-1, 1)   # 315°（左下）
]

# ========================== 生命周期 ==========================
func _ready() -> void:
	_parent = get_parent()
	if not _parent is CharacterBody2D:
		push_error("MovementComponent: 父节点不是 CharacterBody2D！")
		queue_free()

# ========================== 公共 API ==========================
## 设置移动输入（从 InputManager 获取原始向量）
## 此函数应在 _physics_process 中每帧调用
func update_movement(input_direction: Vector2, delta: float) -> void:
	if not _parent:
		return
	
	# 8方向标准化（可选，也可以使用原始方向，但一般动作游戏需要）
	current_direction = normalize_8_direction(input_direction)
	
	# 计算目标速度
	var target_velocity: Vector2 = current_direction * speed
	
	if use_acceleration:
		# 平滑到达目标速度
		if current_direction == Vector2.ZERO:
			# 无输入 -> 减速度减速
			current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration * delta)
		else:
			# 有输入 -> 加速度加速
			current_velocity = current_velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# 直接设置速度
		current_velocity = target_velocity
	
	# 应用到父节点的 velocity 属性
	_parent.velocity = current_velocity

## 立即停止移动（重置 current_velocity）
func stop_immediately() -> void:
	current_velocity = Vector2.ZERO
	current_direction = Vector2.ZERO
	if _parent:
		_parent.velocity = Vector2.ZERO

## 获取当前运动方向（标准化后）
func get_movement_direction() -> Vector2:
	return current_direction

## 获取当前即时速度向量（像素/秒）
func get_current_velocity() -> Vector2:
	return current_velocity

## 获取当前速度是否接近零（可用于判断是否静止）
func is_idle(tolerance: float = 5.0) -> bool:
	return current_velocity.length() < tolerance

## 8方向标准化：将任意向量映射到 8 个主方向之一
## 如果输入向量长度接近零，返回 Vector2.ZERO
## @param dir: 原始输入向量（未经标准化）
## @return 标准化后的 8 方向向量
static func normalize_8_direction(dir: Vector2) -> Vector2:
	if dir.length() < 0.01:
		return Vector2.ZERO
	
	var normalized = dir.normalized()
	var angle = normalized.angle()
	
	# 找到最接近的预设方向
	var best_dir = EIGHT_DIRECTIONS[0]
	var min_diff = abs(angle - best_dir.angle())
	
	for candidate in EIGHT_DIRECTIONS:
		var diff = abs(angle - candidate.angle())
		if diff < min_diff:
			min_diff = diff
			best_dir = candidate
	
	return best_dir

## 可选：返回原始的 8 方向枚举（便于其他系统使用）
static func get_eight_direction_enum(dir: Vector2) -> int:
	if dir.length() < 0.01:
		return -1
	var eight_dir = normalize_8_direction(dir)
	for i in range(EIGHT_DIRECTIONS.size()):
		if eight_dir == EIGHT_DIRECTIONS[i]:
			return i
	return -1

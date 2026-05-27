# ==============================================================================
#   player_movement_component.gd
#   功能：玩家移动组件，将输入方向转为速度并应用到父节点。
#        根据游戏状态自动切换移动模式：
#        - 大厅（LOBBY）：四方向移动（上下左右），适配等距视角
#        - 冒险（IN_GAME）：仅水平移动（左右），适配横版视角
# ==============================================================================
extends Node
class_name PlayerMovementComponent

# ========================== 变量定义模块 ==========================
## 移动速度（像素/秒）
var _speed: float = 100.0
## 当前运动方向（8 方向标准化后的向量）
var current_direction: Vector2 = Vector2.ZERO
## 最后有效移动方向（用于动画朝向等，非 ZERO 时由 update_movement() 自动更新）
var last_direction: Vector2 = Vector2.RIGHT
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

## 功能：从 InputManager 拉取输入，计算移动速度并应用到父节点
## 参数：delta (float) - 物理帧间隔时间（秒）
##       speed_multiplier (float) - 移速倍率，设为 0 可禁用移动
## 说明：内部通过 InputManager 获取输入，不再需要外部传入方向。
##       last_direction 在 speed_multiplier > 0 且有实际方向时自动更新。
##       大厅（LOBBY）使用四方向移动，冒险（IN_GAME）仅水平移动。
func update_movement(_delta: float, speed_multiplier: float = 1.0) -> void:
	var input_dir := InputManager.get_movement_vector()
	# 根据游戏状态选择移动模式
	if GameManager.current_game_state == GameManager.GameState.LOBBY:
		# 等距大厅：四方向移动
		current_direction = input_dir.normalized() if input_dir.length() > 0.01 else Vector2.ZERO
	else:
		# 横版冒险：仅水平移动
		current_direction = Vector2(input_dir.x, 0.0).normalized() if abs(input_dir.x) > 0.01 else Vector2.ZERO

	if speed_multiplier > 0.0 and current_direction != Vector2.ZERO:
		last_direction = current_direction

	current_velocity = current_direction * _speed * speed_multiplier
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

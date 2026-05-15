# ==============================================================================
#   FxVortex.gd
#   功能：龙卷风技能特效，向前直线移动，碰到物体或超出范围后停止，动画循环播放，
#        停留 1 秒后自动销毁。
# ==============================================================================
extends FxBoot
class_name FxVortex

## 移动速度（像素/秒）
@export var speed: float = 150.0
## 最大飞行距离（像素）
@export var max_range: float = 200.0
## 最大飞行时间（秒），0 表示禁用时间限制
@export var max_flight_time: float = 2.0
## 停止后停留时间（秒）
@export var stop_duration: float = 1.0

## 是否已停止移动
var _stopped: bool = false
## 起始位置（用于计算飞行距离）
var _start_pos: Vector2
## 飞行方向（释放时确定，不再变化）
var _fly_direction: Vector2 = Vector2.RIGHT
## 起始时间（秒）
var _start_time: float = 0.0

@onready var area: Area2D = $Area2D          # 碰撞检测区域
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

## 功能：初始化生命周期模式为 FLYING
func _init() -> void:
	lifetime_mode = LifetimeMode.FLYING

## 功能：连接信号（需要在场景中确保 Area2D 的 body_entered 信号连接到本函数）
func _ready() -> void:
	super._ready()
	if area and not area.body_entered.is_connected(_on_area_entered):
		area.body_entered.connect(_on_area_entered)

## 功能：设置初始位置并记录起点
func setup_position() -> void:
	if is_preview:
		return
	global_position = caster.global_position if caster else Vector2.ZERO
	_start_pos = global_position
	_start_time = Time.get_ticks_msec() / 1000.0
	
	# 记录释放时的方向（只取一次）
	_fly_direction = _get_caster_facing_direction()


## 功能：每帧移动并检测碰撞/距离
func _update_movement(delta: float) -> void:
	if is_preview or _stopped:
		return

	# 移动（使用固定方向）
	var step = _fly_direction * speed * delta
	global_position += step

	# 检查是否应停止
	var should_stop = false
	
	# 1. 距离限制
	if max_range > 0 and global_position.distance_to(_start_pos) >= max_range:
		should_stop = true
	
	# 2. 时间限制
	if not should_stop and max_flight_time > 0:
		var elapsed = Time.get_ticks_msec() / 1000.0 - _start_time
		if elapsed >= max_flight_time:
			should_stop = true
	
	if should_stop:
		_stop()

## 功能：碰撞检测（通过 Area2D 信号触发）
func _on_area_entered(body: Node2D) -> void:
	if _stopped:
		return
	# 忽略施法者自身
	if body == caster:
		return
	_stop()

## 功能：停止移动，启动停留计时器
func _stop() -> void:
	if _stopped:
		return
	_stopped = true
	# 可选：禁用碰撞检测避免重复触发
	if area:
		area.set_deferred("monitoring", false)
	# 停留一段时间后销毁
	await get_tree().create_timer(stop_duration).timeout
	destroy()

## 功能：获取施法者面朝方向（假设 caster 有 last_direction 属性）
func _get_caster_facing_direction() -> Vector2:
	if caster and "last_direction" in caster:
		var dir = caster.get("last_direction") as Vector2
		if dir.length() > 0.0:
			return dir.normalized()
	return Vector2.RIGHT

func _setup_preview_custom() -> void:
	_fly_direction = Vector2.ZERO
	_stopped = false

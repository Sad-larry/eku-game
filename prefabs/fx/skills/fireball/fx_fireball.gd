# ==============================================================================
#   fx_fireball.gd
#   功能：火球术飞行特效，从施法者朝目标方向飞行，若无目标则3秒后自动销毁。
#        命中目标时通过 runner.on_hit() 告知 SkillRunner 计算并发出伤害。
#        火球出手瞬间告知 runner.on_execution_complete() 启动冷却。
# ==============================================================================
extends FxBoot

# ========================== 导出变量模块 ==========================
## 飞行速度（像素/秒）
@export var fly_speed: float = 100.0
## 最长飞行时间（秒），超时自动销毁
@export var max_flight_time: float = 3.0

# ========================== 节点引用模块 ==========================
@onready var sprite_2d: Sprite2D = $Sprite2D

# ========================== 内部变量模块 ==========================
var _fly_direction: Vector2 = Vector2.DOWN
var _has_target: bool = false
var _start_time: float = 0.0   # 记录起始时间（秒）

# ========================== 生命周期模块 ==========================
## 功能：初始化时设置生命周期模式为 FLYING
func _init() -> void:
	lifetime_mode = LifetimeMode.FLYING

## 功能：基类 _ready 已处理预览/启动，此处告知 SkillRunner 冷却开始
func _ready() -> void:
	super._ready()
	if not is_preview and runner:
		runner.on_execution_complete()

# ========================== 重写移动逻辑 ==========================
## 功能：每帧移动火球，检测是否命中目标或超时销毁
## 参数：delta (float) - 帧间隔时间（秒）
func _update_movement(delta: float) -> void:
	global_position += _fly_direction * fly_speed * delta

	# 超时销毁
	var elapsed = Time.get_ticks_msec() / 1000.0 - _start_time
	if elapsed >= max_flight_time:
		destroy()
		return

	# 有目标时命中检测
	if _has_target and target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist < 10.0:
			_on_hit()
			return

func _on_hit() -> void:
	if runner:
		runner.on_hit(target)
	destroy()

# ========================== 重写定位方法 ==========================
## 功能：定位火球起始位置并确定飞行方向；若无目标则3秒后自动销毁
func setup_position() -> void:
	global_position = caster.global_position
	_start_time = Time.get_ticks_msec() / 1000.0

	if target and is_instance_valid(target):
		_fly_direction = (target.global_position - caster.global_position).normalized()
		_has_target = true
	else:
		_fly_direction = _get_caster_facing_direction()
		_has_target = false

	if sprite_2d:
		sprite_2d.rotation = _fly_direction.angle()

# ========================== 辅助方法模块 ==========================
## 功能：安全获取施法者面朝方向（确保返回单位向量）
func _get_caster_facing_direction() -> Vector2:
	if caster and "last_direction" in caster:
		var dir := caster.get("last_direction") as Vector2
		if dir.length() > 0.0:
			return dir.normalized()
		return Vector2.DOWN
	return Vector2.DOWN

## 功能：预览模式的自定义设置（静止火球、方向归零）
func _setup_preview_custom() -> void:
	_fly_direction = Vector2.ZERO
	if sprite_2d:
		sprite_2d.rotation = 0.0
	scale = Vector2(2, 2)

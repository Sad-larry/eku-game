# ==============================================================================
#   FxFireball.gd
#   功能：火球术飞行特效，从施法者朝目标方向飞行，若无目标则3秒后自动销毁。
#        适配新版 FxBoot 基类，支持对象池和预览模式。
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

## 功能：基类 _ready 已处理预览/启动，此处可添加额外初始化
func _ready() -> void:
	super._ready()  # 调用基类 _ready（内部自动处理预览或 start）
	# 注意：基类 start() 会调用 setup_position 和 play_animation，
	# 所以这里不需要重复调用。

# ========================== 重写移动逻辑 ==========================
## 功能：每帧移动火球，若无目标则启动自动销毁计时
## 参数：delta (float) - 帧间隔时间（秒）
func _update_movement(delta: float) -> void:
	# 预览模式下不会调用此方法（基类 _process 中已过滤）
	global_position += _fly_direction * fly_speed * delta
	# 超时销毁（基于时间）
	var elapsed = Time.get_ticks_msec() / 1000.0 - _start_time
	if elapsed >= max_flight_time:
		destroy()
		return

	# 有目标时命中检测
	if _has_target and target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist < 10.0:   # 命中阈值
			_on_hit()
			return
func _on_hit() -> void:
	# 触发伤害（示例）
	# EventBus.skill_hit.emit(skill_data, target)
	destroy()
# ========================== 重写定位方法 ==========================
## 功能：定位火球起始位置并确定飞行方向；若无目标则3秒后自动销毁
func setup_position() -> void:
	# 起始位置为施法者位置
	global_position = caster.global_position
	_start_time = Time.get_ticks_msec() / 1000.0   # 记录起始时间（秒）

	# 确定飞行方向
	if target and is_instance_valid(target):
		_fly_direction = (target.global_position - caster.global_position).normalized()
		_has_target = true
	else:
		_fly_direction = _get_caster_facing_direction()
		_has_target = false

	# 旋转精灵方向
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
## 说明：基类已自动居中、播放预览动画，此处只需额外调整
func _setup_preview_custom() -> void:
	# 预览模式下禁止移动
	_fly_direction = Vector2.ZERO
	# 精灵旋转归零（避免倾斜）
	if sprite_2d:
		sprite_2d.rotation = 0.0
	# 可选：预览时缩放略微缩小
	scale = Vector2(2, 2)

# ========================== 命中检测（示例，可按需实现） ==========================
## 功能：在飞行过程中检测是否命中目标（例如每帧判断距离）
## 说明：可在 _update_movement 中调用，命中时调用 destroy() 并触发伤害
func _check_hit() -> void:
	if not _has_target:
		return
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist < 10.0:  # 命中阈值
			# 触发伤害逻辑（可通过信号或直接调用技能系统）
			# 例如：EventBus.skill_hit.emit(skill_data, target)
			destroy()

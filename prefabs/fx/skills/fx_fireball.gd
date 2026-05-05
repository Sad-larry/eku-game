# ==============================================================================
#   FxFireball.gd
#   功能：火球术飞行特效，从施法者朝目标方向飞行，若无目标则3秒后自动销毁。
#        当前版本仅实现移动效果，不包含伤害逻辑。
# ==============================================================================
extends FxBoot
class_name FxFireball

# ========================== 导出变量模块 ==========================
## 飞行速度（像素/秒）
@export var fly_speed: float = 100.0

# ========================== 节点引用模块 ==========================
@onready var sprite_2d: Sprite2D = $Sprite2D

# ========================== 内部变量模块 ==========================
var _fly_direction: Vector2 = Vector2.DOWN
var _has_target: bool = false
## 无目标时的生命周期倒计时（秒），在 _process 中递减，随暂停自然冻结
var _no_target_lifetime: float = 0.0

# ========================== 生命周期模块 ==========================
## 功能：进入场景树时初始化位置、方向、动画
## 说明：不调用父类 _ready()，按需定制
func _ready() -> void:
	setup_position()
	play_animation()

## 功能：每帧移动火球，若无目标则启动自动销毁计时器
## 参数：delta (float) - 帧间隔时间（秒）
func _process(delta: float) -> void:
	global_position += _fly_direction * fly_speed * delta
	
	# 无目标时自动销毁计时（_process 在暂停时不会运行，倒计时自然暂停）
	if not _has_target and _no_target_lifetime > 0.0:
		_no_target_lifetime -= delta
		if _no_target_lifetime <= 0.0:
			queue_free()

# ========================== 重写 FxBoot 方法模块 ==========================
## 功能：定位火球起始位置并确定飞行方向；若无目标则3秒后自动销毁
func setup_position() -> void:
	global_position = caster.global_position

	# 确定飞行方向
	if target and is_instance_valid(target):
		_fly_direction = (target.global_position - caster.global_position).normalized()
		_has_target = true
	else:
		_fly_direction = _get_caster_facing_direction()
		_has_target = false
		_no_target_lifetime = 3.0

	# 旋转精灵方向
	if sprite_2d:
		sprite_2d.rotation = _fly_direction.angle()

## 功能：播放火球飞行循环动画
func play_animation() -> void:
	if animation_player and animation_player.has_animation("fly"):
		animation_player.play("fly")

## 功能：不自动销毁，改由超时或命中时手动销毁
func auto_destroy() -> void:
	pass

# ========================== 辅助方法模块 ==========================
## 功能：安全获取施法者面朝方向（确保返回单位向量）
func _get_caster_facing_direction() -> Vector2:
	if caster and "last_direction" in caster:
		var dir := caster.get("last_direction") as Vector2
		if dir.length() > 0.0:
			return dir.normalized()
		return Vector2.DOWN
	return Vector2.DOWN

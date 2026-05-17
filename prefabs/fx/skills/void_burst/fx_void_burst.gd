# ==============================================================================
#   FxVoidBurst.gd
#   功能：虚空迸发终结技，在目标位置（敌人）或施法者前方（空放）生成能量球，
#        蓄力 0.8 秒后炸裂，对范围内敌人造成一次范围伤害。
#        命中目标时通过 runner.on_hit() 告知 SkillRunner 计算并发出伤害。
#        能量球出手后告知 runner.on_execution_complete() 启动冷却。
# ==============================================================================
extends FxBoot
class_name FxVoidBurst

# ========================== 导出变量模块 ==========================
## 爆炸范围检测半径（像素），需与场景中 CollisionShape2D 的 CircleShape2D 半径一致
@export var explosion_radius: float = 60.0
## 蓄力时长（秒），能量球从生成到炸裂的等待时间
@export var charge_duration: float = 0.8
## 空放时生成位置距施法者的距离（像素）
@export var fallback_distance: float = 80.0

# ========================== 节点引用模块 ==========================
@onready var area: Area2D = $Area2D

# ========================== 生命周期模块 ==========================
## 功能：初始化时设置生命周期模式为 ONESHOT
func _init() -> void:
	lifetime_mode = LifetimeMode.ONESHOT

## 功能：基类 _ready 会执行 start()，能量球出手即冷却
func _ready() -> void:
	super._ready()
	if not is_preview and runner:
		runner.on_execution_complete()

# ========================== FxBoot 钩子重写 ==========================
## 功能：预览模式 — 停在蓄力动画首帧
func _setup_preview_custom() -> void:
	if animation_player and animation_player.has_animation("slash"):
		animation_player.play("slash")
		animation_player.pause()

## 功能：定位能量球位置 — 有目标挂敌人，无目标空放施法者前方
func setup_position() -> void:
	if is_preview:
		return
	if target and is_instance_valid(target):
		global_position = target.global_position
	elif caster:
		var dir = _get_caster_facing_direction()
		global_position = caster.global_position + dir * fallback_distance
	else:
		global_position = Vector2.ZERO

## 功能：播放蓄力动画，等待蓄力完成，执行爆炸
func play_animation() -> void:
	if is_preview:
		return
	if not animation_player:
		destroy()
		return

	# 蓄力阶段 — 播放 slash 动画
	if animation_player.has_animation("slash"):
		animation_player.play("slash")

	# 等待蓄力时长
	await get_tree().create_timer(charge_duration).timeout

	# 爆炸阶段 — 检测范围内敌人并造成伤害
	if area:
		for body in area.get_overlapping_bodies():
			if body == caster:
				continue
			if body.is_in_group("enemies") and runner:
				runner.on_hit(body)

	# 等待爆炸动画（slash 动画剩余部分播放完毕）
	if animation_player.has_animation("slash") and animation_player.is_playing():
		await animation_player.animation_finished

	destroy()

# ========================== 辅助方法模块 ==========================
## 功能：安全获取施法者面朝方向
func _get_caster_facing_direction() -> Vector2:
	if caster and "last_direction" in caster:
		var dir := caster.get("last_direction") as Vector2
		if dir.length() > 0.0:
			return dir.normalized()
		return Vector2.DOWN
	return Vector2.DOWN

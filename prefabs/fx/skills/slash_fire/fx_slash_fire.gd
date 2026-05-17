# ==============================================================================
#   fx_slash_fire.gd
#   功能：地火斩技能特效，在施法者前方地面生成一团火焰，播放动画后自动销毁。
#        无移动逻辑，仅为一次性视觉效果。
#        生成后立即调用 runner.on_execution_complete() 启动冷却。
# ==============================================================================
extends FxBoot
class_name FxSlashFire

## 火焰出现位置相对于施法者的偏移量（像素）
@export var offset: Vector2 = Vector2(50, 0)

## 功能：初始化生命周期模式为 ONESHOT
func _init() -> void:
	lifetime_mode = LifetimeMode.ONESHOT

## 功能：基类 _ready 会自动执行 start()，生成后告知 SkillRunner 启动冷却
func _ready() -> void:
	super._ready()
	if not is_preview and runner:
		runner.on_execution_complete()

## 功能：设置火焰位置为施法者前方偏移处
func setup_position() -> void:
	if is_preview:
		return
	global_position = (caster.global_position if caster else Vector2.ZERO) + offset

## 功能：播放火焰动画（需在 AnimationPlayer 中创建名为 "slash" 的动画，时长 0.6 秒）
func play_animation() -> void:
	super.play_animation()
	# 等待动画播放完成后销毁特效
	await animation_player.animation_finished
	destroy()

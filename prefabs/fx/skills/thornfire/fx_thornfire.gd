# ==============================================================================
#   fx_thornfire.gd
#   功能：生存技能"荆棘花"特效，在施法者身上绽放一朵花，动画结束后特效仍跟随
#        玩家移动（如头顶花朵），直到技能效果持续时间 skill_duration 结束被销毁。
#        数值效果（增加 10 点攻击）由技能系统单独处理，本脚本仅负责视觉表现。
#        绽放后立即调用 runner.on_execution_complete() 启动冷却。
# ==============================================================================
extends FxBoot
class_name FxThornfire

# ========================== 生命周期模块 ==========================
## 功能：初始化时设置生命周期模式为 FOLLOW（跟随目标）
func _init() -> void:
	lifetime_mode = LifetimeMode.FOLLOW

## 功能：基类 _ready 会自动执行 start()，绽放后告知 SkillRunner 启动冷却
func _ready() -> void:
	super._ready()
	if not is_preview and runner:
		runner.on_execution_complete()

# ========================== 重写钩子方法 ==========================
## 功能：设置初始位置为施法者位置（预览模式下由基类自动居中）
func setup_position() -> void:
	if is_preview:
		return
	global_position = caster.global_position if caster else Vector2.ZERO

## 功能：播放绽放动画（只播放一次）
func play_animation() -> void:
	super.play_animation()
	await animation_player.animation_finished
	destroy()

## 功能：每帧更新位置，跟随施法者移动
## 参数：_delta (float) - 帧间隔时间（未使用，仅满足虚函数签名）
func _update_movement(_delta: float) -> void:
	if is_preview or not caster:
		return
	global_position = caster.global_position

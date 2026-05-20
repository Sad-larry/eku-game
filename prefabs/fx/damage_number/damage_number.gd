# ==============================================================================
#   damage_number.gd
#   功能：伤害数字显示控件，用于战斗场景中弹出伤害数值、暴击特效、
#        治疗数值等视觉反馈。动画结束后自动回收至对象池。
# ==============================================================================
extends Node2D
class_name DamageNumber

## 伤害类型枚举
enum DamageType {
	NORMAL,  ## 普通伤害
	CRIT,    ## 暴击伤害
	HEAL,    ## 治疗
}

# ========================== 常量定义模块 ==========================
## 不同伤害类型的显示颜色
const _COLORS: Dictionary = {
	DamageType.NORMAL: Color.WHITE,
	DamageType.CRIT:   Color(1.0, 0.85, 0.0),
	DamageType.HEAL:   Color.GREEN,
}

## 动画参数
const _POPUP_DURATION := 0.2    ## 弹出阶段时长
const _FADE_DURATION := 0.6     ## 淡出阶段时长
const _TOTAL_DURATION := _POPUP_DURATION + _FADE_DURATION
const _RISE_DISTANCE := 60.0    ## 上飘总距离
const _OVERSHOOT_SCALE := 1.2   ## 弹出过冲缩放

# ========================== 回调类型 ==========================
## 回收回调类型（由 DamagePopupSpawner 注入）
var _recycle_callback: Callable

# ========================== 节点引用模块 ==========================
@onready var _label: Label = $ValueLabel
var _tween: Tween

# ========================== 公共 API 模块 ==========================
## 功能：以数值初始化（伤害/治疗）
func setup(value: float, type: DamageType = DamageType.NORMAL) -> void:
	_label.text = str(int(value))
	_label.self_modulate = _COLORS.get(type, Color.WHITE)
	_play_animation()

## 功能：以自定义文本初始化（如 "+1 尘元"）
func setup_text(text: String, color: Color = Color.WHITE) -> void:
	_label.text = text
	_label.self_modulate = color
	_play_animation()

## 功能：中断动画并重置状态（供对象池回收前调用）
func reset() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	_label.position = Vector2.ZERO
	_label.scale = Vector2.ONE
	_label.self_modulate.a = 1.0

# ========================== 动画模块 ==========================
func _play_animation() -> void:
	_label.position = Vector2.ZERO
	_label.scale = Vector2(0.5, 0.5)
	_label.self_modulate.a = 1.0

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)

	# 阶段 1：弹出（位置上移 + 缩放过冲）
	_tween.tween_property(_label, "position:y", -_RISE_DISTANCE * 0.4, _POPUP_DURATION) \
		.set_trans(Tween.TRANS_BACK)
	_tween.parallel().tween_property(_label, "scale", Vector2(_OVERSHOOT_SCALE, _OVERSHOOT_SCALE), _POPUP_DURATION) \
		.set_trans(Tween.TRANS_BACK)

	# 阶段 2：缓慢上飘 + 缩放恢复 + 淡出
	_tween.tween_property(_label, "position:y", -_RISE_DISTANCE, _FADE_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	_tween.parallel().tween_property(_label, "scale", Vector2.ONE, _FADE_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	_tween.parallel().tween_property(_label, "self_modulate:a", 0.0, _FADE_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)

	_tween.finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	if _recycle_callback.is_valid():
		_recycle_callback.call(self)
	else:
		queue_free()

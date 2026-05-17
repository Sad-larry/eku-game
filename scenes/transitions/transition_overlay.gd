# ==============================================================================
#   transition_overlay.gd
#   功能：场景过渡覆盖层控件，提供淡入淡出动画和加载进度显示功能。
#        用于场景加载器（SceneLoader）实现平滑的场景切换视觉效果。
# ==============================================================================
extends CanvasLayer
class_name TransitionOverlay

# ========================== 信号声明模块 ==========================
## 触发时机：淡入动画完成（遮罩从不透明变为透明）
signal fade_in_finished

## 触发时机：淡出动画完成（遮罩从透明变为不透明）
signal fade_out_finished

# ========================== 节点引用模块 ==========================
## 纯色矩形（用于遮罩效果）
@onready var color_rect: ColorRect = $ColorRect

## 加载进度文本标签
@onready var progress_label: Label = $ProgressLabel

# ========================== 内部变量模块 ==========================
## 当前活动的 Tween 动画实例（用于安全中断）
var _tween: Tween

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化界面状态（透明遮罩，隐藏进度标签）
func _ready() -> void:
	color_rect.color = Color.BLACK
	color_rect.modulate = Color.TRANSPARENT
	progress_label.hide()

# ========================== 公共 API 模块 ==========================
## 功能：淡入动画（遮罩从透明变为不透明）
## 参数：duration (float) - 动画持续时间（秒），默认 0.3
## 说明：完成后发射 fade_in_finished 信号
func fade_in(duration: float = 0.3) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(color_rect, "modulate", Color.WHITE, duration)
	await _tween.finished
	fade_in_finished.emit()

## 功能：淡出动画（遮罩从不透明变为透明）
## 参数：duration (float) - 动画持续时间（秒），默认 0.3
## 说明：完成后发射 fade_out_finished 信号
func fade_out(duration: float = 0.3) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(color_rect, "modulate", Color.TRANSPARENT, duration)
	await _tween.finished
	fade_out_finished.emit()

## 功能：更新加载进度文本显示
## 参数：percent (float) - 加载进度（范围 0.0 ~ 1.0）
## 说明：自动转换为百分比（0% ~ 100%）并显示文本
func set_progress(percent: float) -> void:
	var pct := clampi(int(percent * 100.0), 0, 100)
	progress_label.text = "加载中… %d%%" % pct
	progress_label.show()

## 功能：隐藏加载进度文本
func hide_progress() -> void:
	progress_label.hide()

## 功能：重置覆盖层为初始状态（透明遮罩，隐藏进度标签）
func reset() -> void:
	_kill_tween()
	color_rect.modulate = Color.TRANSPARENT
	progress_label.hide()

# ========================== 内部辅助方法模块 ==========================
## 功能：安全中断当前正在播放的 Tween 动画
func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

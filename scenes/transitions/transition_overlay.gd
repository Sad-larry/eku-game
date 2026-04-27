extends CanvasLayer
class_name TransitionOverlay

@onready var color_rect: ColorRect = $ColorRect
@onready var progress_label: Label = $ProgressLabel

## 淡入（遮罩显现），完成后发射
signal fade_in_finished

## 淡出（遮罩消失），完成后发射
signal fade_out_finished

var _tween: Tween


func _ready() -> void:
	color_rect.color = Color.BLACK
	color_rect.modulate = Color.TRANSPARENT
	progress_label.hide()


## 从透明 → 不透明
func fade_in(duration: float = 0.3) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(color_rect, "modulate", Color.WHITE, duration)
	await _tween.finished
	fade_in_finished.emit()


## 从不透明 → 透明
func fade_out(duration: float = 0.3) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(color_rect, "modulate", Color.TRANSPARENT, duration)
	await _tween.finished
	fade_out_finished.emit()


## 更新进度文本
func set_progress(percent: float) -> void:
	var pct := clampi(int(percent * 100.0), 0, 100)
	progress_label.text = "加载中… %d%%" % pct
	progress_label.show()


## 重置为初始状态（透明遮罩）
func reset() -> void:
	_kill_tween()
	color_rect.modulate = Color.TRANSPARENT
	progress_label.hide()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

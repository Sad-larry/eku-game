# ==============================================================================
#   confirm_dialog.gd
#   功能：通用确认对话框组件，带半透明遮罩和淡入淡出动画。
#        用于需要玩家二选一的场景（传送门确认、退出确认、商人购买等）。
# ==============================================================================
extends CanvasLayer
class_name ConfirmDialog

# ========================== 信号声明模块 ==========================
## 触发时机：玩家点击确认按钮
signal confirmed
## 触发时机：玩家点击取消按钮或关闭对话框
signal canceled

# ========================== 节点引用模块 ==========================
@onready var _overlay: ColorRect = $Overlay
@onready var _dialog_bg: Panel = $DialogBG
@onready var _message_label: Label = %MessageLabel
@onready var _confirm_btn: Button = %ConfirmBtn
@onready var _cancel_btn: Button = %CancelBtn

# ========================== 常量定义模块 ==========================
const _FADE_DURATION := 0.15

# ========================== 变量定义模块 ==========================
## 动画期间锁定输入，防止重复触发
var _input_locked: bool = true

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_confirm_btn.pressed.connect(_on_confirm)
	_cancel_btn.pressed.connect(_on_cancel)
	_dialog_bg.modulate.a = 0.0
	_overlay.visible = false
	_fade_in()

# ========================== 公共 API 模块 ==========================
## 功能：设置对话框显示文本
func set_message(text: String) -> void:
	_message_label.text = text

## 功能：自定义按钮文本
func set_buttons(confirm_text: String, cancel_text: String) -> void:
	_confirm_btn.text = confirm_text
	_cancel_btn.text = cancel_text

# ========================== 动画模块 ==========================
func _fade_in() -> void:
	_overlay.visible = true
	var tween := create_tween()
	tween.tween_property(_dialog_bg, "modulate:a", 1.0, _FADE_DURATION)
	await tween.finished
	_input_locked = false

func _close() -> void:
	_input_locked = true
	var tween := create_tween()
	tween.tween_property(_dialog_bg, "modulate:a", 0.0, _FADE_DURATION)
	await tween.finished
	queue_free()

# ========================== 回调模块 ==========================
func _on_confirm() -> void:
	if _input_locked:
		return
	confirmed.emit()
	_close()

func _on_cancel() -> void:
	if _input_locked:
		return
	canceled.emit()
	_close()

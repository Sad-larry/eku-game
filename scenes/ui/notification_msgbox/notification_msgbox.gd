# notification_manager.gd
extends CanvasLayer
class_name NotificationMsgbox

@onready var panel: Panel = $Panel
@onready var label: Label = %Label

func _ready():
	panel.visible = false

func show_message(text: String, duration: float = 2.0) -> void:
	label.text = text
	panel.visible = true
	
	# 淡入
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(duration).timeout
	# 淡出
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	panel.visible = false
	queue_free()   # 销毁自身，触发 tree_exited 信号

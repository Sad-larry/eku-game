# ==============================================================================
#   notification_manager.gd
#   功能：通知消息浮窗控件，支持淡入淡出动画显示文本消息，显示指定时长后自动淡出并销毁自身。
#        通常由 UIManager 动态实例化并添加到场景中。
# ==============================================================================
extends CanvasLayer
class_name NotificationMsgbox

# ========================== 节点引用模块 ==========================
## 消息面板容器（用于显示背景和承载标签）
@onready var panel: Panel = $Panel

## 消息文本标签（需在场景中通过 %Label 唯一命名）
@onready var label: Label = %Label

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时隐藏面板（等待 show_message 调用）
func _ready():
	panel.visible = false

# ========================== 公共 API 模块 ==========================
## 功能：显示一条通知消息（带淡入淡出动画）
## 参数：text (String) - 要显示的消息文本；duration (float) - 显示时长（秒），默认 2.0 秒
## 说明：消息显示期间会阻塞直到动画完成，完成后自动销毁自身节点
func show_message(text: String, duration: float = 2.0) -> void:
	label.text = text
	panel.visible = true
	
	# 淡入动画（透明度 0 → 1，耗时 0.2 秒）
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	
	# 等待指定显示时长
	await get_tree().create_timer(duration).timeout
	
	# 淡出动画（透明度 1 → 0，耗时 0.2 秒）
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	panel.visible = false
	# 销毁自身节点，触发 tree_exited 信号
	queue_free()

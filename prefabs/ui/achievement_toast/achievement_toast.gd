# ==============================================================================
#   achievement_toast.gd
#   功能：成就解锁提示UI，显示成就解锁的通知。
# ==============================================================================
extends Control

# ========================== 节点引用 ==========================
@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/VBoxContainer/Name
@onready var desc_label: Label = $HBoxContainer/VBoxContainer/Description

# ========================== 变量 ==========================
## 显示持续时间
var _display_time: float = 3.0

## 计时器
var _timer: float = 0.0

## 是否正在显示
var _is_showing: bool = false

# ========================== 生命周期 ==========================
func _ready() -> void:
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	hide()

func _process(delta: float) -> void:
	if not _is_showing:
		return

	_timer += delta
	if _timer >= _display_time:
		_hide_toast()

# ========================== 公共 API ==========================
func show_toast(data: AchievementData) -> void:
	if data == null:
		return

	if icon and data.icon:
		icon.texture = data.icon
	if name_label:
		name_label.text = "成就解锁: " + data.display_name
	if desc_label:
		desc_label.text = data.description

	_timer = 0.0
	_is_showing = true
	show()

# ========================== 内部方法 ==========================
func _hide_toast() -> void:
	_is_showing = false
	hide()

# ========================== 信号回调 ==========================
func _on_achievement_unlocked(achievement_id: String) -> void:
	var data: AchievementData = AchievementManager.get_all_achievements().get(achievement_id)
	if data:
		show_toast(data)

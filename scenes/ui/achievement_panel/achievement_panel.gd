# ==============================================================================
#   achievement_panel.gd
#   功能：成就面板UI，显示所有成就及其解锁状态。
# ==============================================================================
extends Control

# ========================== 节点引用 ==========================
@onready var title_label: Label = $VBoxContainer/Title
@onready var achievement_list: VBoxContainer = $VBoxContainer/ScrollContainer/AchievementList
@onready var close_button: Button = $VBoxContainer/CloseButton

# ========================== 生命周期 ==========================
func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	hide()

# ========================== 公共 API ==========================
func show_panel() -> void:
	_refresh_display()
	show()

func hide_panel() -> void:
	hide()

# ========================== 内部方法 ==========================
func _refresh_display() -> void:
	# 清空旧内容
	for child in achievement_list.get_children():
		child.queue_free()

	if not AchievementManager.ENABLED:
		if title_label:
			title_label.text = "成就 (已禁用)"
		return

	# 获取所有成就并排序
	var all_achievements: Dictionary = AchievementManager.get_all_achievements()
	var sorted_achievements: Array = all_achievements.values()
	sorted_achievements.sort_custom(func(a, b): return a.sort_order < b.sort_order)

	for data in sorted_achievements:
		var item := _create_achievement_item(data)
		achievement_list.add_child(item)

	# 更新标题
	if title_label:
		var unlocked: int = AchievementManager.get_unlocked_count()
		var total: int = AchievementManager.get_total_count()
		title_label.text = "成就 (%d/%d)" % [unlocked, total]

func _create_achievement_item(data: AchievementData) -> HBoxContainer:
	var item := HBoxContainer.new()

	# 图标
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if data.icon:
		icon.texture = data.icon
	item.add_child(icon)

	# 信息容器
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 名称
	var name_label := Label.new()
	if AchievementManager.is_unlocked(data.id):
		name_label.text = data.display_name
		name_label.modulate = Color(1, 1, 1)
	elif data.is_hidden:
		name_label.text = "???"
		name_label.modulate = Color(0.5, 0.5, 0.5)
	else:
		name_label.text = data.display_name
		name_label.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(name_label)

	# 描述
	var desc_label := Label.new()
	if AchievementManager.is_unlocked(data.id):
		desc_label.text = data.description
		desc_label.modulate = Color(0.8, 0.8, 0.8)
	elif data.is_hidden:
		desc_label.text = "隐藏成就"
		desc_label.modulate = Color(0.4, 0.4, 0.4)
	else:
		desc_label.text = data.description
		desc_label.modulate = Color(0.6, 0.6, 0.6)
	info.add_child(desc_label)

	item.add_child(info)

	# 状态
	var status_label := Label.new()
	if AchievementManager.is_unlocked(data.id):
		status_label.text = "✓"
		status_label.modulate = Color(0.2, 1, 0.2)
	else:
		var progress: int = AchievementManager.get_progress(data.id)
		if data.condition_value > 0:
			status_label.text = "%d/%d" % [progress, data.condition_value]
		else:
			status_label.text = "未解锁"
		status_label.modulate = Color(0.6, 0.6, 0.6)
	item.add_child(status_label)

	return item

func _on_close_pressed() -> void:
	hide_panel()

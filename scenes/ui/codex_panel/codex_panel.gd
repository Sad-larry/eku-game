# ==============================================================================
#   codex_panel.gd
#   功能：图鉴主面板UI，显示图鉴分类和条目列表。
# ==============================================================================
extends Control

# ========================== 节点引用 ==========================
@onready var title_label: Label = $VBoxContainer/Title
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
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
	# 更新标题
	if title_label:
		var progress: Dictionary = CodexManager.get_progress()
		title_label.text = "图鉴 (%d/%d)" % [progress.unlocked, progress.total]

	# 清空旧标签页
	for child in tab_container.get_children():
		child.queue_free()

	# 创建各类型标签页
	_create_tab("敌人", CodexEntry.CodexType.ENEMY)
	_create_tab("技能", CodexEntry.CodexType.SKILL)
	_create_tab("遗物", CodexEntry.CodexType.RELIC)
	_create_tab("武器", CodexEntry.CodexType.WEAPON)
	_create_tab("BOSS", CodexEntry.CodexType.BOSS)

func _create_tab(tab_name: String, codex_type: CodexEntry.CodexType) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name

	var list := VBoxContainer.new()
	list.name = "List"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var entries: Array[CodexEntry] = CodexManager.get_entries_by_type(codex_type)
	entries.sort_custom(func(a, b): return a.sort_order < b.sort_order)

	for entry in entries:
		var item := _create_entry_item(entry)
		list.add_child(item)

	# 显示解锁进度
	var unlocked: int = CodexManager.get_unlocked_count_by_type(codex_type)
	var total: int = CodexManager.get_total_count_by_type(codex_type)
	var progress_label := Label.new()
	progress_label.text = "解锁进度: %d/%d" % [unlocked, total]
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(progress_label)

	tab_container.add_child(scroll)

func _create_entry_item(entry: CodexEntry) -> HBoxContainer:
	var item := HBoxContainer.new()

	# 图标
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if entry.icon:
		icon.texture = entry.icon
	item.add_child(icon)

	# 信息容器
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 名称
	var name_label := Label.new()
	if CodexManager.is_unlocked(entry.id):
		name_label.text = entry.display_name
		name_label.modulate = Color(1, 1, 1)
	else:
		name_label.text = "???"
		name_label.modulate = Color(0.5, 0.5, 0.5)
	info.add_child(name_label)

	# 描述
	var desc_label := Label.new()
	if CodexManager.is_unlocked(entry.id):
		desc_label.text = entry.description
		desc_label.modulate = Color(0.8, 0.8, 0.8)
	else:
		desc_label.text = entry.unlock_condition if entry.unlock_condition else "未解锁"
		desc_label.modulate = Color(0.4, 0.4, 0.4)
	info.add_child(desc_label)

	item.add_child(info)

	# 状态
	var status_label := Label.new()
	if CodexManager.is_unlocked(entry.id):
		status_label.text = "✓"
		status_label.modulate = Color(0.2, 1, 0.2)
	else:
		status_label.text = "🔒"
		status_label.modulate = Color(0.6, 0.6, 0.6)
	item.add_child(status_label)

	return item

func _on_close_pressed() -> void:
	hide_panel()

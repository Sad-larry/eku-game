# ==============================================================================
#   relic_selection.gd
#   功能：遗物选择对话框（CanvasLayer 根节点），居中显示 3 个遗物选项供玩家选择。
#        选择后自动获取遗物并关闭界面。
# ==============================================================================
extends CanvasLayer
class_name RelicSelectionDialog

# ========================== 节点引用模块 ==========================
@onready var _option_container: HBoxContainer = %OptionContainer

# ========================== 内部变量模块 ==========================
var _options: Array[RelicData] = []
var _option_panels: Array[PanelContainer] = []
var _is_selected: bool = false

# ========================== 公共 API ==========================
## 功能：设置遗物选项并初始化显示
func setup(options: Array[RelicData]) -> void:
	_options = options
	_is_selected = false

func _ready() -> void:
	_build_option_cards()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# 不允许跳过选择，必须选一个
		get_viewport().set_input_as_handled()

# ========================== 卡牌构建 ==========================
func _build_option_cards() -> void:
	# 清除旧卡牌
	for panel in _option_panels:
		if is_instance_valid(panel):
			panel.queue_free()
	_option_panels.clear()

	for i in _options.size():
		var relic: RelicData = _options[i]
		var panel := _create_card(relic, i)
		_option_container.add_child(panel)
		_option_panels.append(panel)

func _create_card(relic: RelicData, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 240)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 悬停高亮
	var style := StyleBoxFlat.new()
	style.bg_color = _get_rarity_bg_color(relic.rarity)
	style.border_color = _get_rarity_border_color(relic.rarity)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# 稀有度标签
	var rarity_label := Label.new()
	rarity_label.text = _get_rarity_name(relic.rarity)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", _get_rarity_border_color(relic.rarity))
	vbox.add_child(rarity_label)

	# 图标
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.texture = relic.icon
	vbox.add_child(icon_rect)

	# 名称
	var name_label := Label.new()
	name_label.text = relic.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)

	# 描述
	var desc_label := Label.new()
	desc_label.text = relic.description if not relic.description.is_empty() else "无描述"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	# 点击按钮覆盖
	var btn := Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(180, 240)
	btn.pressed.connect(_on_option_selected.bind(index))
	# 将按钮作为直接子节点覆盖在 panel 上
	panel.add_child(btn)

	return panel

# ========================== 选择处理 ==========================
func _on_option_selected(index: int) -> void:
	if _is_selected:
		return
	_is_selected = true

	if index < 0 or index >= _options.size():
		queue_free()
		return

	var relic: RelicData = _options[index]
	RelicManager.acquire_relic(relic)

	if Global.DEBUG_MODE:
		print("[RelicSelection] 选择了遗物: ", relic.display_name)

	queue_free()

# ========================== 辅助方法 ==========================
func _get_rarity_name(rarity: RelicData.Rarity) -> String:
	match rarity:
		RelicData.Rarity.COMMON: return "普通"
		RelicData.Rarity.UNCOMMON: return "精良"
		RelicData.Rarity.RARE: return "稀有"
		RelicData.Rarity.EPIC: return "史诗"
		RelicData.Rarity.LEGENDARY: return "传说"
		_: return "未知"

func _get_rarity_bg_color(rarity: RelicData.Rarity) -> Color:
	match rarity:
		RelicData.Rarity.COMMON: return Color(0.15, 0.15, 0.15, 0.9)
		RelicData.Rarity.UNCOMMON: return Color(0.1, 0.2, 0.1, 0.9)
		RelicData.Rarity.RARE: return Color(0.1, 0.1, 0.25, 0.9)
		RelicData.Rarity.EPIC: return Color(0.2, 0.1, 0.25, 0.9)
		RelicData.Rarity.LEGENDARY: return Color(0.25, 0.2, 0.05, 0.9)
		_: return Color(0.15, 0.15, 0.15, 0.9)

func _get_rarity_border_color(rarity: RelicData.Rarity) -> Color:
	match rarity:
		RelicData.Rarity.COMMON: return Color(0.6, 0.6, 0.6)
		RelicData.Rarity.UNCOMMON: return Color(0.2, 0.8, 0.2)
		RelicData.Rarity.RARE: return Color(0.3, 0.5, 1.0)
		RelicData.Rarity.EPIC: return Color(0.7, 0.3, 1.0)
		RelicData.Rarity.LEGENDARY: return Color(1.0, 0.8, 0.2)
		_: return Color(0.5, 0.5, 0.5)

func get_blocked_input_prefixes() -> Array[String]:
	return ["skill_", "attack"]

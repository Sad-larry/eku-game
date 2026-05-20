# ==============================================================================
#   skill_selection_dialog.gd
#   功能：技能选择对话框（CanvasLayer 根节点），居中显示技能浏览/装备面板。
#        左侧为带分类过滤的技能卡牌网格，右侧显示详情和特效预览。
#        左侧 FloatPanel 显示当前已装备技能槽，点击选择装备目标槽位。
# ==============================================================================
extends CanvasLayer
class_name SkillSelectionDialog

# ========================== 常量模块 ==========================
const TAB_TO_TYPE: Dictionary = {
	0: -1,
	1: SkillEffect.SkillType.INITIATOR,
	2: SkillEffect.SkillType.FINISHER,
	3: SkillEffect.SkillType.CONTROL,
	4: SkillEffect.SkillType.SURVIVAL
}
const FILTER_NAMES: Array = ["全部", "起手技", "连携技", "场控技", "生存技"]

# ========================== 节点引用模块 ==========================
@onready var _filter_tabs: TabBar = %FilterTabs
@onready var _card_grid: GridContainer = %CardGrid
@onready var _detail_icon: TextureRect = %DetailIcon
@onready var _detail_name: Label = %DetailName
@onready var _detail_type: Label = %DetailType
@onready var _detail_desc: Label = %StatDetailDesc
@onready var _stat_cooldown: Label = %StatCooldown
@onready var _stat_energy: Label = %StatEnergy
@onready var _stat_damage: Label = %StatDamage
@onready var _stat_multiplier: Label = %StatMultiplier
@onready var _preview_container: Control = %PreviewContainer
@onready var _equip_btn: Button = %EquipButton

# ========================== FloatPanel 节点引用模块 ==========================
@onready var _slot_buttons: Array[Button] = [
	%SlotButton1,
	%SlotButton2,
	%SlotButton3,
	%SlotButton4,
]
@onready var _slot_icons: Array[TextureRect] = [
	%SlotIcon1,
	%SlotIcon2,
	%SlotIcon3,
	%SlotIcon4,
]
@onready var _slot_highlights: Array[Panel] = [
	%SlotHighlight1,
	%SlotHighlight2,
	%SlotHighlight3,
	%SlotHighlight4,
]

# ========================== 内部变量模块 ==========================
var _selected_skill_id: String = ""                  # 当前选中的技能 ID
var _equipped_ids: Array = []                        # 已装备的技能 ID 列表
var _current_filter: int = -1                        # 当前过滤器类型，-1 表示全部
var _card_instances: Array[SkillSelectionCard] = []  # 卡牌实例列表
var _selected_slot_index: int = 0                    # FloatPanel 选中的技能槽索引

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	for name_text in FILTER_NAMES:
		_filter_tabs.add_tab(name_text)

	_filter_tabs.tab_changed.connect(_on_tab_changed)
	_equip_btn.pressed.connect(_on_equip_pressed)

	_equipped_ids = _get_equipped_skill_ids()
	_init_slot_panel()
	_rebuild_card_grid()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()

# ========================== FloatPanel 模块 ==========================
## 功能：初始化 FloatPanel 中的技能槽显示和按钮连接
func _init_slot_panel() -> void:
	for i in range(_slot_buttons.size()):
		_slot_buttons[i].pressed.connect(_on_slot_button_pressed.bind(i))
		_update_slot_display(i)
	_select_slot(0)

## 功能：更新指定技能槽的显示（图标/占位）
func _update_slot_display(slot_index: int) -> void:
	var player := Global.player
	if not player:
		_slot_icons[slot_index].texture = null
		return
	var action_name := "skill_%d" % [slot_index + 1]
	var data := player.skill_manager.get_data_by_action(action_name)
	_slot_icons[slot_index].texture = data.icon if data else null

## 功能：选中 FloatPanel 中的某个技能槽
func _select_slot(slot_index: int) -> void:
	_selected_slot_index = slot_index
	for i in range(_slot_highlights.size()):
		_slot_highlights[i].visible = (i == slot_index)

## 功能：FloatPanel 技能槽按钮被点击时选中该槽
func _on_slot_button_pressed(slot_index: int) -> void:
	_select_slot(slot_index)

# ========================== 卡牌管理模块 ==========================
func _rebuild_card_grid() -> void:
	for card in _card_instances:
		if is_instance_valid(card):
			card.queue_free()
	_card_instances.clear()

	var skills: Array
	if _current_filter < 0:
		skills = SkillLibrary.get_all_skills().values()
	else:
		skills = SkillLibrary.get_skills_by_type(_current_filter)

	for data in skills:
		if not data is SkillEffect:
			continue
		var card: SkillSelectionCard = Global.SKILL_CARD_SCENE.instantiate()
		_card_grid.add_child(card)
		card.setup(data, _equipped_ids)
		card.selected.connect(_on_card_selected)
		# 未解锁技能：灰色显示 + 禁用点击
		if not SkillUnlockManager.is_skill_unlocked(data.id):
			card.self_modulate = Color(0.4, 0.4, 0.4)
			card.disabled = true
			card.tooltip_text = "未解锁 - 请前往商店解锁"
		_card_instances.append(card)

	if _card_instances.is_empty():
		_clear_detail()
	else:
		# 优先选中第一个已解锁卡牌
		var first_unlocked: SkillSelectionCard = null
		for card in _card_instances:
			if SkillUnlockManager.is_skill_unlocked(card.skill_data.id):
				first_unlocked = card
				break
		if first_unlocked:
			_on_card_selected(first_unlocked.skill_data.id)
		else:
			_on_card_selected(_card_instances[0].skill_data.id)

# ========================== 详情显示模块 ==========================
func _clear_detail() -> void:
	_detail_icon.texture = null
	_detail_name.text = ""
	_detail_type.text = ""
	_detail_desc.text = ""
	_stat_cooldown.text = ""
	_stat_energy.text = ""
	_stat_damage.text = ""
	_stat_multiplier.text = ""
	_equip_btn.text = "装备技能"
	_equip_btn.disabled = true
	for child in _preview_container.get_children():
		child.queue_free()

func _on_card_selected(skill_id: String) -> void:
	_selected_skill_id = skill_id
	for card in _card_instances:
		if is_instance_valid(card):
			card.set_highlight(card.skill_data.id == skill_id)

	var data = SkillLibrary.get_skill_by_id(skill_id)
	if data:
		_show_skill_detail(data)

func _show_skill_detail(data: SkillEffect) -> void:
	_detail_icon.texture = data.icon
	_detail_name.text = data.name

	var type_name = SkillEffect.SkillType.keys()[data.type]
	_detail_type.text = type_name
	match data.type:
		SkillEffect.SkillType.INITIATOR:
			_detail_type.self_modulate = Color(0.2, 0.8, 0.2)
		SkillEffect.SkillType.FINISHER:
			_detail_type.self_modulate = Color(0.8, 0.2, 0.2)
		SkillEffect.SkillType.CONTROL:
			_detail_type.self_modulate = Color(0.2, 0.4, 0.8)
		SkillEffect.SkillType.SURVIVAL:
			_detail_type.self_modulate = Color(0.8, 0.6, 0.2)
		_:
			_detail_type.self_modulate = Color(0.5, 0.5, 0.5)

	_detail_desc.text = data.description if data.description else "暂无描述"
	_stat_cooldown.text = "%.1f 秒" % data.cooldown
	_stat_energy.text = "%d" % data.energy_cost
	_stat_damage.text = "%.1f" % data.damage
	_stat_multiplier.text = "x %.1f" % data.skill_multiplier

	_show_skill_preview(data)

	var is_unlocked := SkillUnlockManager.is_skill_unlocked(_selected_skill_id)
	if not is_unlocked:
		_equip_btn.text = "未解锁"
		_equip_btn.disabled = true
	else:
		var is_equipped = _selected_skill_id in _equipped_ids
		_equip_btn.text = "已装备" if is_equipped else "装备技能"
		_equip_btn.disabled = is_equipped

func _show_skill_preview(data: SkillEffect) -> void:
	for child in _preview_container.get_children():
		child.queue_free()
	if not data.fx_scene:
		return

	var fx = data.fx_scene.instantiate()
	fx.is_preview = true
	_preview_container.add_child(fx)

	await get_tree().process_frame
	if fx is Node2D:
		fx.position = _preview_container.size * 0.5

# ========================== 装备操作模块 ==========================
## 功能：点击"装备技能"按钮，将当前选中技能装备到选中的技能槽
func _on_equip_pressed() -> void:
	if not Global.player or _selected_skill_id.is_empty():
		return
	var success = Global.player.skill_manager.equip_skill_to_slot(
		_selected_skill_id, _selected_slot_index
	)
	if success:
		_equipped_ids = _get_equipped_skill_ids()
		_equip_btn.text = "已装备"
		_equip_btn.disabled = true
		_update_slot_display(_selected_slot_index)
		for card in _card_instances:
			if is_instance_valid(card):
				card.setup(card.skill_data, _equipped_ids)
	else:
		UIManager.show_message("技能已装备或技能栏已满")

# ========================== 过滤器模块 ==========================
func _on_tab_changed(index: int) -> void:
	_current_filter = TAB_TO_TYPE.get(index, -1)
	_rebuild_card_grid()

func get_blocked_input_prefixes() -> Array[String]:
	return ["skill_", "attack"]

# ========================== 关闭模块 ==========================
func _on_close_button_pressed() -> void:
	queue_free()

# ========================== 辅助方法模块 ==========================
func _get_equipped_skill_ids() -> Array:
	if not Global.player:
		return []
	return Global.player.skill_manager.get_equipped_ids()

# ==============================================================================
#   lobby_shop.gd
#   功能：大厅商店界面控制器，左侧显示技能列表（带分类过滤），右侧显示技能详情
#        和解锁操作。支持尘元消费解锁技能，与 SkillUnlockManager 和 CurrencyManager 交互。
# ==============================================================================
extends CanvasLayer
class_name LobbyShop

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
@onready var _item_list: VBoxContainer = %ItemList
@onready var _coin_label: Label = %CoinLabel
@onready var _detail_icon: TextureRect = %DetailIcon
@onready var _detail_name: Label = %DetailName
@onready var _detail_type: Label = %DetailType
@onready var _detail_desc: Label = %DetailDesc
@onready var _stat_cooldown: Label = %StatCooldown
@onready var _stat_energy: Label = %StatEnergy
@onready var _stat_damage: Label = %StatDamage
@onready var _stat_multiplier: Label = %StatMultiplier
@onready var _condition_label: Label = %ConditionLabel
@onready var _cost_label: Label = %CostLabel
@onready var _unlock_btn: Button = %UnlockButton
@onready var _upgrade_section: VBoxContainer = %UpgradeSection
@onready var _level_label: Label = %LevelLabel
@onready var _upgrade_effect_label: Label = %UpgradeEffectLabel
@onready var _upgrade_cost_label: Label = %UpgradeCostLabel
@onready var _upgrade_btn: Button = %UpgradeButton

# ========================== 内部变量模块 ==========================
var _selected_skill_id: String = ""
var _current_filter: int = -1
var _item_instances: Array[ShopSkillListItem] = []

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	for name_text in FILTER_NAMES:
		_filter_tabs.add_tab(name_text)

	_filter_tabs.tab_changed.connect(_on_tab_changed)
	_unlock_btn.pressed.connect(_on_unlock_pressed)
	_upgrade_btn.pressed.connect(_on_upgrade_pressed)
	CurrencyManager.coin_changed.connect(_on_coin_changed)
	SkillUpgradeManager.skill_upgraded.connect(_on_skill_upgraded)

	_update_coin_display()
	_rebuild_list()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()

# ========================== 列表管理模块 ==========================
func _rebuild_list() -> void:
	for item in _item_instances:
		if is_instance_valid(item):
			item.queue_free()
	_item_instances.clear()

	var skills: Array
	if _current_filter < 0:
		skills = SkillLibrary.get_all_skills().values()
	else:
		skills = SkillLibrary.get_skills_by_type(_current_filter)

	for data in skills:
		if not data is SkillEffect:
			continue
		var item: ShopSkillListItem = load("res://scenes/ui/lobby_shop/shop_skill_list_item.tscn").instantiate()
		_item_list.add_child(item)
		item.setup(data)
		item.selected.connect(_on_item_selected)
		_item_instances.append(item)

	if _item_instances.is_empty():
		_clear_detail()
	else:
		_on_item_selected(_item_instances[0].skill_data.id)

# ========================== 选择与详情模块 ==========================
func _on_item_selected(skill_id: String) -> void:
	_selected_skill_id = skill_id
	for item in _item_instances:
		if is_instance_valid(item):
			item.set_highlight(item.skill_data.id == skill_id)

	var data = SkillLibrary.get_skill_by_id(skill_id)
	if data:
		_show_detail(data)

func _show_detail(data: SkillEffect) -> void:
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

	_update_unlock_section(data.id)
	_update_upgrade_section(data.id)

func _clear_detail() -> void:
	_detail_icon.texture = null
	_detail_name.text = ""
	_detail_type.text = ""
	_detail_desc.text = ""
	_stat_cooldown.text = ""
	_stat_energy.text = ""
	_stat_damage.text = ""
	_stat_multiplier.text = ""
	_condition_label.text = ""
	_cost_label.text = ""
	_unlock_btn.text = "解锁"
	_unlock_btn.disabled = true
	_upgrade_section.visible = false

# ========================== 解锁操作模块 ==========================
func _update_unlock_section(skill_id: String) -> void:
	var unlock_data := SkillUnlockManager.get_unlock_data(skill_id)
	if unlock_data == null:
		return

	if unlock_data.is_unlocked:
		_condition_label.text = ""
		_cost_label.text = ""
		_unlock_btn.text = "已解锁"
		_unlock_btn.disabled = true
	else:
		# 前置技能条件
		var prereq_text := ""
		for prereq in unlock_data.prerequisite_skills:
			var prereq_data := SkillLibrary.get_skill_by_id(prereq)
			var prereq_name := prereq_data.name if prereq_data else prereq
			if SkillUnlockManager.is_skill_unlocked(prereq):
				prereq_text += "  [已解锁] %s\n" % prereq_name
			else:
				prereq_text += "  [未解锁] %s\n" % prereq_name
		_condition_label.text = "前置技能:\n%s" % prereq_text if not prereq_text.is_empty() else ""

		# 费用显示
		var cost := unlock_data.unlock_cost
		if cost <= 0:
			_cost_label.text = "免费"
		else:
			_cost_label.text = "费用: %d 尘元" % cost

		# 按钮状态
		var can_unlock := SkillUnlockManager.can_unlock_skill(skill_id)
		_unlock_btn.text = "解锁"
		_unlock_btn.disabled = not can_unlock

func _on_unlock_pressed() -> void:
	if _selected_skill_id.is_empty():
		return

	var success := SkillUnlockManager.unlock_skill(_selected_skill_id)
	if success:
		# 刷新列表项状态
		for item in _item_instances:
			if is_instance_valid(item):
				item.refresh_state()
				item.refresh_level()
		# 刷新详情面板
		var data = SkillLibrary.get_skill_by_id(_selected_skill_id)
		if data:
			_show_detail(data)

# ========================== 升级操作模块 ==========================
## 功能：根据技能解锁状态和等级更新升级区域显示
func _update_upgrade_section(skill_id: String) -> void:
	var is_unlocked := SkillUnlockManager.is_skill_unlocked(skill_id)
	_upgrade_section.visible = is_unlocked
	if not is_unlocked:
		return

	var level: int = SkillUpgradeManager.get_skill_level(skill_id)
	var max_level: int = SkillUpgradeManager.get_max_level(skill_id)
	_level_label.text = "等级: Lv.%d/%d" % [level, max_level]

	if level >= max_level:
		_upgrade_effect_label.text = "已达到最大等级"
		_upgrade_cost_label.text = ""
		_upgrade_btn.text = "已满级"
		_upgrade_btn.disabled = true
		return

	# 下一级效果预览
	var cum := SkillUpgradeManager.get_cumulative_effect(skill_id)
	var next_cum := _get_next_level_cumulative(skill_id)
	var dmg_bonus: float = next_cum.get("damage_multiplier_bonus", 0.0) - cum.get("damage_multiplier_bonus", 0.0)
	var cd_reduction: float = next_cum.get("cooldown_reduction", 0.0) - cum.get("cooldown_reduction", 0.0)
	var energy_reduction: int = next_cum.get("energy_cost_reduction", 0) - cum.get("energy_cost_reduction", 0)

	var effect_parts: Array[String] = []
	if dmg_bonus > 0:
		effect_parts.append("+%d%% 伤害" % int(dmg_bonus * 100))
	if cd_reduction > 0:
		effect_parts.append("-%d%% 冷却" % int(cd_reduction * 100))
	if energy_reduction > 0:
		effect_parts.append("-%d 能耗" % energy_reduction)
	_upgrade_effect_label.text = "下一级: " + ", ".join(effect_parts) if not effect_parts.is_empty() else ""

	# 费用
	var cost: int = SkillUpgradeManager.get_upgrade_cost(skill_id)
	_upgrade_cost_label.text = "费用: %d 尘元" % cost

	# 按钮状态
	var can_upgrade := SkillUpgradeManager.can_upgrade_skill(skill_id)
	_upgrade_btn.text = "升级"
	_upgrade_btn.disabled = not can_upgrade

## 功能：获取下一级的累积效果（用于计算单级增量）
func _get_next_level_cumulative(skill_id: String) -> Dictionary:
	var config: SkillUpgradeData = SkillUpgradeManager._upgrade_configs.get(skill_id)
	if config == null:
		return {}
	var current_level: int = SkillUpgradeManager.get_skill_level(skill_id)
	var result := {"damage_multiplier_bonus": 0.0, "cooldown_reduction": 0.0, "energy_cost_reduction": 0}
	for i in range(current_level):  # current_level 个效果（比当前多一级）
		if i < config.level_effects.size():
			var effect: SkillUpgradeEffect = config.level_effects[i]
			result["damage_multiplier_bonus"] += effect.damage_multiplier_bonus
			result["cooldown_reduction"] += effect.cooldown_reduction
			result["energy_cost_reduction"] += effect.energy_cost_reduction
	return result

func _on_upgrade_pressed() -> void:
	if _selected_skill_id.is_empty():
		return
	var success := SkillUpgradeManager.upgrade_skill(_selected_skill_id)
	if success:
		# 刷新列表项等级
		for item in _item_instances:
			if is_instance_valid(item):
				item.refresh_level()
		# 刷新详情面板
		var data = SkillLibrary.get_skill_by_id(_selected_skill_id)
		if data:
			_show_detail(data)

func _on_skill_upgraded(_skill_id: String, _new_level: int) -> void:
	# 信号回调，由 _on_upgrade_pressed 内部已处理刷新
	pass

# ========================== 货币显示模块 ==========================
func _update_coin_display() -> void:
	_coin_label.text = "尘元: %d" % CurrencyManager.get_permanent_coin()

func _on_coin_changed(_current: int, permanent: int) -> void:
	_coin_label.text = "尘元: %d" % permanent
	# 余额变化可能影响解锁/升级按钮状态
	if not _selected_skill_id.is_empty():
		_update_unlock_section(_selected_skill_id)
		_update_upgrade_section(_selected_skill_id)

# ========================== 过滤器模块 ==========================
func _on_tab_changed(index: int) -> void:
	_current_filter = TAB_TO_TYPE.get(index, -1)
	_rebuild_list()

func get_blocked_input_prefixes() -> Array[String]:
	return ["skill_", "attack"]

# ========================== 关闭模块 ==========================
func _on_close_button_pressed() -> void:
	queue_free()

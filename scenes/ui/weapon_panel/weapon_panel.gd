# ==============================================================================
#   weapon_panel.gd
#   功能：武器面板UI，显示当前装备的武器信息、属性、附魔和武器技能。
# ==============================================================================
extends Control

# ========================== 节点引用模块 ==========================
@onready var weapon_name_label: Label = $VBoxContainer/WeaponName
@onready var weapon_desc_label: Label = $VBoxContainer/WeaponDesc
@onready var weapon_level_label: Label = $VBoxContainer/WeaponLevel
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var enchants_container: VBoxContainer = $VBoxContainer/EnchantsContainer
@onready var upgrade_button: Button = $VBoxContainer/ButtonsContainer/UpgradeButton
@onready var close_button: Button = $VBoxContainer/ButtonsContainer/CloseButton
@onready var weapon_skill_label: Label = $VBoxContainer/WeaponSkill

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(_on_close_pressed)
	EventBus.weapon_upgraded.connect(_on_weapon_changed)
	EventBus.weapon_enchanted.connect(_on_weapon_changed)
	EventBus.weapon_equipped.connect(_on_weapon_changed.bind(""))
	hide()

# ========================== 公共 API 模块 ==========================
## 功能：显示武器面板
func show_panel() -> void:
	_refresh_display()
	show()

## 功能：隐藏武器面板
func hide_panel() -> void:
	hide()

# ========================== 内部方法模块 ==========================
## 功能：刷新显示内容
func _refresh_display() -> void:
	if not WeaponManager.ENABLED:
		_show_empty_state()
		return

	var weapon = WeaponManager.get_equipped_weapon()
	if weapon == null:
		_show_empty_state()
		return

	# 武器名称和描述
	if weapon_name_label:
		weapon_name_label.text = weapon.display_name
	if weapon_desc_label:
		weapon_desc_label.text = weapon.description

	# 武器等级
	var level: int = WeaponManager.get_weapon_level(weapon.id)
	if weapon_level_label:
		weapon_level_label.text = "Lv.%d / %d" % [level, weapon.max_level]

	# 武器属性
	var stats: Dictionary = WeaponManager.get_effective_stats(weapon.id)
	_update_stats_display(stats)

	# 附魔信息
	var enchants: Array = WeaponManager.get_weapon_enchants(weapon.id)
	_update_enchants_display(enchants)

	# 武器技能信息
	_update_weapon_skill_display(weapon)

	# 升级按钮状态
	_update_upgrade_button(weapon)

## 功能：显示空状态
func _show_empty_state() -> void:
	if weapon_name_label:
		weapon_name_label.text = "未装备武器"
	if weapon_desc_label:
		weapon_desc_label.text = ""
	if weapon_level_label:
		weapon_level_label.text = ""
	if weapon_skill_label:
		weapon_skill_label.text = ""
	if upgrade_button:
		upgrade_button.disabled = true
		upgrade_button.text = "升级"

## 功能：更新属性显示
func _update_stats_display(stats: Dictionary) -> void:
	if stats_container == null:
		return

	# 清空旧内容
	for child in stats_container.get_children():
		child.queue_free()

	# 添加属性行
	_add_stat_row("攻击力", "%.1f" % stats.get("damage", 0))
	_add_stat_row("攻击速度", "%.2f/秒" % stats.get("attack_speed", 0))
	_add_stat_row("暴击率", "%.1f%%" % (stats.get("crit_rate", 0) * 100))
	_add_stat_row("暴击伤害", "%.1f%%" % (stats.get("crit_damage", 0) * 100))
	_add_stat_row("攻击范围", "%.0f" % stats.get("attack_range", 0))

	# 显示标签
	var tags: Array = stats.get("tags", [])
	if tags.size() > 0:
		_add_stat_row("标签", ", ".join(tags))

## 功能：添加属性行
func _add_stat_row(label_text: String, value_text: String) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(label)
	hbox.add_child(value)
	stats_container.add_child(hbox)

## 功能：更新附魔显示
func _update_enchants_display(enchants: Array) -> void:
	if enchants_container == null:
		return

	# 清空旧内容
	for child in enchants_container.get_children():
		child.queue_free()

	if enchants.is_empty():
		var label := Label.new()
		label.text = "无附魔"
		label.modulate = Color(0.6, 0.6, 0.6)
		enchants_container.add_child(label)
		return

	for enchant in enchants:
		var label := Label.new()
		label.text = "✦ %s" % enchant.display_name
		label.modulate = Color(0.8, 0.9, 1.0)
		enchants_container.add_child(label)

## 功能：更新武器技能显示
func _update_weapon_skill_display(weapon) -> void:
	if weapon_skill_label == null:
		return

	if weapon.weapon_skill:
		weapon_skill_label.text = "武器技能: %s (CD: %.1fs)" % [weapon.weapon_skill.name, weapon.weapon_skill_cooldown]
	else:
		weapon_skill_label.text = "无武器技能"

## 功能：更新升级按钮状态
func _update_upgrade_button(weapon) -> void:
	if upgrade_button == null:
		return

	var cost: int = WeaponManager.get_upgrade_cost(weapon.id)
	if cost < 0:
		upgrade_button.disabled = true
		upgrade_button.text = "已满级"
	else:
		upgrade_button.disabled = false
		upgrade_button.text = "升级 (%d 尘元)" % cost

# ========================== 信号回调模块 ==========================
## 功能：升级按钮点击
func _on_upgrade_pressed() -> void:
	var weapon = WeaponManager.get_equipped_weapon()
	if weapon == null:
		return
	WeaponManager.upgrade_weapon(weapon.id)

## 功能：关闭按钮点击
func _on_close_pressed() -> void:
	hide_panel()

## 功能：武器变化时刷新显示
func _on_weapon_changed(_a = "", _b = "") -> void:
	if visible:
		_refresh_display()

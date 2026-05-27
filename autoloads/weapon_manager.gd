# ==============================================================================
#   weapon_manager.gd
#   功能：武器管理器（Autoload 单例），管理武器的持有、装备、升级、附魔。
#        与 SaveManager 协作持久化数据，与 CurrencyManager 协作完成扣费。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 WeaponManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 模块启用开关（后期系统，暂时禁用）
const ENABLED: bool = false
## 调试模式开关
const DEBUG_MODE: bool = true
## 武器资源目录
const WEAPONS_DIR: String = "res://resources/data/weapons/weapons/"
## 默认武器ID（新玩家初始获得）
const DEFAULT_WEAPON_ID: String = "sword_iron"

# ========================== 信号声明模块 ==========================
## 触发时机：武器装备时
signal weapon_equipped(weapon_id: String)

## 触发时机：武器卸下时
signal weapon_unequipped(weapon_id: String)

## 触发时机：武器升级时
signal weapon_upgraded(weapon_id: String, new_level: int)

## 触发时机：武器附魔时
signal weapon_enchanted(weapon_id: String, enchant_id: String)

## 触发时机：武器技能使用时
signal weapon_skill_used(weapon_id: String)

# ========================== 内部变量模块 ==========================
## 已拥有的武器 {weapon_id: WeaponData}
var _owned_weapons: Dictionary = {}
## 当前装备的武器
var _equipped_weapon: WeaponData = null
## 武器等级 {weapon_id: int}
var _weapon_levels: Dictionary = {}
## 武器附魔 {weapon_id: Array[WeaponEnchant]}
var _weapon_enchants: Dictionary = {}
## 武器技能冷却计时器 {weapon_id: remaining_seconds}
var _skill_cooldowns: Dictionary = {}

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	if not ENABLED:
		print("WeaponManager: 已禁用")
		return
	SaveManager.data_loaded.connect(_on_save_data_loaded)
	print("WeaponManager: 武器管理器初始化完成")

func _process(delta: float) -> void:
	# 更新武器技能冷却
	for weapon_id in _skill_cooldowns:
		if _skill_cooldowns[weapon_id] > 0.0:
			_skill_cooldowns[weapon_id] -= delta

# ========================== 存档集成模块 ==========================
## 功能：SaveManager 数据加载后，从存档恢复武器数据
func _on_save_data_loaded() -> void:
	var section: Dictionary = SaveManager.get_section("weapons", _get_default_section())

	# 恢复武器等级
	_weapon_levels = {}
	var saved_levels: Dictionary = section.get("weapon_levels", {})
	for weapon_id in saved_levels:
		_weapon_levels[weapon_id] = saved_levels[weapon_id]

	# 恢复武器附魔
	_weapon_enchants = {}
	# 附魔是运行时数据，不需要持久化（附魔在每次运行中获取）

	# 加载已拥有的武器资源
	var owned_ids: Array = section.get("owned_weapons", [])
	for weapon_id in owned_ids:
		var weapon: WeaponData = _load_weapon_resource(weapon_id)
		if weapon:
			_owned_weapons[weapon_id] = weapon

	# 如果没有任何武器，给予默认武器
	if _owned_weapons.is_empty():
		_grant_default_weapon()

	# 恢复装备状态
	var equipped_id: String = section.get("equipped_weapon", "")
	if equipped_id != "" and _owned_weapons.has(equipped_id):
		_equipped_weapon = _owned_weapons[equipped_id]
	elif not _owned_weapons.is_empty():
		# 装备第一个可用武器
		_equipped_weapon = _owned_weapons.values()[0]

	if DEBUG_MODE:
		print("[WeaponManager] 已加载武器数据，拥有武器: ", _owned_weapons.size(), " | 装备: ", _equipped_weapon.display_name if _equipped_weapon else "无")

## 功能：获取默认数据段
func _get_default_section() -> Dictionary:
	return {
		"owned_weapons": [],
		"equipped_weapon": "",
		"weapon_levels": {},
		"weapon_enchants": {}
	}

## 功能：将当前武器数据同步到 SaveManager 并保存
func _sync_to_save() -> void:
	var owned_ids: Array[String] = []
	for weapon_id in _owned_weapons:
		owned_ids.append(weapon_id)

	var equipped_id: String = ""
	if _equipped_weapon:
		equipped_id = _equipped_weapon.id

	SaveManager.set_section("weapons", {
		"owned_weapons": owned_ids,
		"equipped_weapon": equipped_id,
		"weapon_levels": _weapon_levels.duplicate(),
		"weapon_enchants": {}
	})
	SaveManager.save_immediately()

## 功能：加载武器资源文件
func _load_weapon_resource(weapon_id: String) -> WeaponData:
	var path: String = WEAPONS_DIR + weapon_id + ".tres"
	if ResourceLoader.exists(path):
		return load(path) as WeaponData
	push_warning("[WeaponManager] 武器资源不存在: ", path)
	return null

## 功能：授予默认武器
func _grant_default_weapon() -> void:
	var weapon: WeaponData = _load_weapon_resource(DEFAULT_WEAPON_ID)
	if weapon:
		_owned_weapons[weapon.id] = weapon
		_weapon_levels[weapon.id] = 1
		_equipped_weapon = weapon
		_sync_to_save()
		if DEBUG_MODE:
			print("[WeaponManager] 授予默认武器: ", weapon.display_name)

# ========================== 公共查询 API ==========================
## 功能：获取当前装备的武器
## 返回值：WeaponData - 当前武器，无武器时返回 null
func get_equipped_weapon() -> WeaponData:
	return _equipped_weapon

## 功能：获取武器的有效属性（含等级和附魔加成）
## 参数：weapon_id (String) - 武器 ID
## 返回值：Dictionary - 有效属性字典
func get_effective_stats(weapon_id: String) -> Dictionary:
	var weapon: WeaponData = _owned_weapons.get(weapon_id)
	if weapon == null:
		return {}

	var level: int = _weapon_levels.get(weapon_id, 1)
	var level_index: int = clampi(level - 1, 0, weapon.level_multipliers.size() - 1) if weapon.level_multipliers.size() > 0 else 0
	var multiplier: float = weapon.level_multipliers[level_index] if weapon.level_multipliers.size() > 0 else 1.0
	var enchants: Array[WeaponEnchant] = _weapon_enchants.get(weapon_id, [])

	var stats: Dictionary = {
		"damage": weapon.base_damage * multiplier,
		"attack_speed": weapon.attack_speed,
		"crit_rate": weapon.crit_rate,
		"crit_damage": weapon.crit_damage,
		"attack_range": weapon.attack_range,
		"tags": weapon.tags.duplicate(),
		"level": level,
		"weapon_skill": weapon.weapon_skill,
		"weapon_skill_cooldown": weapon.weapon_skill_cooldown
	}

	# 叠加附魔效果
	for enchant in enchants:
		stats["damage"] += enchant.damage_bonus
		stats["crit_rate"] += enchant.crit_rate_bonus
		stats["crit_damage"] += enchant.crit_damage_bonus
		stats["attack_speed"] += enchant.attack_speed_bonus
		if enchant.element_tag != "":
			stats["tags"].append(enchant.element_tag)

	return stats

## 功能：获取当前装备武器的有效属性
## 返回值：Dictionary - 有效属性字典
func get_equipped_stats() -> Dictionary:
	if _equipped_weapon == null:
		return {}
	return get_effective_stats(_equipped_weapon.id)

## 功能：获取所有已拥有的武器
## 返回值：Array[WeaponData] - 武器列表
func get_owned_weapons() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for weapon in _owned_weapons.values():
		result.append(weapon)
	return result

## 功能：获取武器的当前等级
## 参数：weapon_id (String) - 武器 ID
## 返回值：int - 武器等级
func get_weapon_level(weapon_id: String) -> int:
	return _weapon_levels.get(weapon_id, 1)

## 功能：获取武器的附魔列表
## 参数：weapon_id (String) - 武器 ID
## 返回值：Array[WeaponEnchant] - 附魔列表
func get_weapon_enchants(weapon_id: String) -> Array[WeaponEnchant]:
	return _weapon_enchants.get(weapon_id, [])

## 功能：检查武器技能是否就绪
## 参数：weapon_id (String) - 武器 ID
## 返回值：bool - true 表示技能可用
func is_weapon_skill_ready(weapon_id: String) -> bool:
	var cooldown: float = _skill_cooldowns.get(weapon_id, 0.0)
	return cooldown <= 0.0

## 功能：获取武器技能冷却剩余时间
## 参数：weapon_id (String) - 武器 ID
## 返回值：float - 剩余冷却秒数
func get_weapon_skill_cooldown_remaining(weapon_id: String) -> float:
	return maxf(0.0, _skill_cooldowns.get(weapon_id, 0.0))

## 功能：获取武器升级费用
## 参数：weapon_id (String) - 武器 ID
## 返回值：int - 升级费用，无法升级返回 -1
func get_upgrade_cost(weapon_id: String) -> int:
	var weapon: WeaponData = _owned_weapons.get(weapon_id)
	if weapon == null:
		return -1
	var level: int = _weapon_levels.get(weapon_id, 0)
	if level >= weapon.max_level:
		return -1
	if level < weapon.upgrade_costs.size():
		return weapon.upgrade_costs[level]
	# 未配置费用列表时使用默认公式
	return 20 * level

# ========================== 公共操作 API ==========================
## 功能：装备武器
## 参数：weapon_id (String) - 武器 ID
## 返回值：bool - true 表示装备成功
func equip_weapon(weapon_id: String) -> bool:
	if not _owned_weapons.has(weapon_id):
		push_warning("[WeaponManager] 尝试装备未拥有的武器: ", weapon_id)
		return false

	var weapon: WeaponData = _owned_weapons[weapon_id]

	# 卸下当前武器
	if _equipped_weapon:
		var old_id: String = _equipped_weapon.id
		_equipped_weapon = null
		weapon_unequipped.emit(old_id)
		EventBus.weapon_unequipped.emit(old_id)

	# 装备新武器
	_equipped_weapon = weapon
	_sync_to_save()
	weapon_equipped.emit(weapon_id)
	EventBus.weapon_equipped.emit(weapon_id)

	if DEBUG_MODE:
		print("[WeaponManager] 武器已装备: ", weapon.display_name)
	return true

## 功能：卸下武器
## 返回值：bool - true 表示卸下成功
func unequip_weapon() -> bool:
	if _equipped_weapon == null:
		return false

	var old_id: String = _equipped_weapon.id
	_equipped_weapon = null
	_sync_to_save()
	weapon_unequipped.emit(old_id)
	EventBus.weapon_unequipped.emit(old_id)

	if DEBUG_MODE:
		print("[WeaponManager] 武器已卸下: ", old_id)
	return true

## 功能：升级武器
## 参数：weapon_id (String) - 武器 ID
## 返回值：bool - true 表示升级成功
func upgrade_weapon(weapon_id: String) -> bool:
	var weapon: WeaponData = _owned_weapons.get(weapon_id)
	if weapon == null:
		push_warning("[WeaponManager] 尝试升级未拥有的武器: ", weapon_id)
		return false

	var current_level: int = _weapon_levels.get(weapon_id, 0)
	if current_level >= weapon.max_level:
		if DEBUG_MODE:
			print("[WeaponManager] 武器已达最大等级: ", weapon_id)
		return false

	var cost: int = get_upgrade_cost(weapon_id)
	if cost < 0:
		return false

	# 检查永久货币余额
	if CurrencyManager.get_permanent_coin() < cost:
		if DEBUG_MODE:
			print("[WeaponManager] 尘元不足，无法升级: ", weapon_id, " (需要 ", cost, ")")
		return false

	# 扣费
	if not CurrencyManager.spend_coin(cost):
		return false

	# 升级
	_weapon_levels[weapon_id] = current_level + 1
	_sync_to_save()
	weapon_upgraded.emit(weapon_id, current_level + 1)
	EventBus.weapon_upgraded.emit(weapon_id, current_level + 1)

	if DEBUG_MODE:
		print("[WeaponManager] 武器升级成功: ", weapon_id, " Lv.", current_level + 1, " (花费 ", cost, " 尘元)")
	return true

## 功能：为武器添加附魔
## 参数：weapon_id (String) - 武器 ID；enchant (WeaponEnchant) - 附魔数据
## 返回值：bool - true 表示附魔成功
func enchant_weapon(weapon_id: String, enchant: WeaponEnchant) -> bool:
	var weapon: WeaponData = _owned_weapons.get(weapon_id)
	if weapon == null:
		push_warning("[WeaponManager] 尝试附魔未拥有的武器: ", weapon_id)
		return false

	var enchants: Array[WeaponEnchant] = _weapon_enchants.get(weapon_id, [])
	if enchants.size() >= weapon.max_enchant_slots:
		if DEBUG_MODE:
			print("[WeaponManager] 附魔槽已满: ", weapon_id, " (", enchants.size(), "/", weapon.max_enchant_slots, ")")
		return false

	enchants.append(enchant)
	_weapon_enchants[weapon_id] = enchants
	_sync_to_save()
	weapon_enchanted.emit(weapon_id, enchant.id)
	EventBus.weapon_enchanted.emit(weapon_id, enchant.id)

	if DEBUG_MODE:
		print("[WeaponManager] 武器附魔成功: ", weapon_id, " + ", enchant.display_name)
	return true

## 功能：使用武器技能
## 参数：weapon_id (String) - 武器 ID（可选，默认使用当前装备武器）
## 返回值：SkillEffect - 武器技能数据，不可用返回 null
func try_get_weapon_skill(weapon_id: String = "") -> SkillEffect:
	if weapon_id == "":
		if _equipped_weapon == null:
			return null
		weapon_id = _equipped_weapon.id

	var weapon: WeaponData = _owned_weapons.get(weapon_id)
	if weapon == null or weapon.weapon_skill == null:
		return null

	# 检查冷却
	if not is_weapon_skill_ready(weapon_id):
		return null

	# 启动冷却
	_skill_cooldowns[weapon_id] = weapon.weapon_skill_cooldown
	weapon_skill_used.emit(weapon_id)
	EventBus.weapon_skill_used.emit(weapon_id)

	return weapon.weapon_skill

## 功能：添加新武器到持有列表
## 参数：weapon (WeaponData) - 武器数据
## 返回值：bool - true 表示添加成功
func add_weapon(weapon: WeaponData) -> bool:
	if weapon == null or weapon.id.is_empty():
		return false

	if _owned_weapons.has(weapon.id):
		if DEBUG_MODE:
			print("[WeaponManager] 武器已拥有: ", weapon.id)
		return false

	_owned_weapons[weapon.id] = weapon
	if not _weapon_levels.has(weapon.id):
		_weapon_levels[weapon.id] = 1
	_sync_to_save()

	if DEBUG_MODE:
		print("[WeaponManager] 获得新武器: ", weapon.display_name)
	return true

## 功能：重置运行时状态（新运行开始时调用）
func reset_run_state() -> void:
	_weapon_enchants.clear()
	_skill_cooldowns.clear()
	if DEBUG_MODE:
		print("[WeaponManager] 运行时状态已重置")

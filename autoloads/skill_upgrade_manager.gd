# ==============================================================================
#   skill_upgrade_manager.gd
#   功能：技能升级状态管理器（Autoload 单例），管理技能等级和升级逻辑，
#        提供运行时有效数值计算，与 SaveManager 协作持久化等级状态，
#        与 CurrencyManager 协作完成扣费。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SkillUpgradeManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
const DEBUG_MODE: bool = true
const UPGRADE_DATA_DIR: String = "res://resources/data/skills/upgrades/"
const DEFAULT_LEVEL: int = 1

# ========================== 信号声明模块 ==========================
## 触发时机：技能升级成功时
## 参数：skill_id (String) - 技能 ID；new_level (int) - 升级后的新等级
signal skill_upgraded(skill_id: String, new_level: int)

# ========================== 内部变量模块 ==========================
## 升级配置字典：{skill_id (String): SkillUpgradeData}
var _upgrade_configs: Dictionary = {}
## 技能等级字典：{skill_id (String): int}
var _skill_levels: Dictionary = {}

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	SaveManager.data_loaded.connect(_on_save_data_loaded)
	print("SkillUpgradeManager: 技能升级管理器初始化完成")

# ========================== 存档集成模块 ==========================
## 功能：SaveManager 数据加载后，从 upgrades/ 目录加载配置并恢复等级状态
func _on_save_data_loaded() -> void:
	_upgrade_configs.clear()
	_skill_levels.clear()

	# 1. 递归加载 upgrades/ 目录下所有 .tres 配置
	_recursive_load_configs(UPGRADE_DATA_DIR)

	# 2. 初始化所有已配置技能的默认等级
	for skill_id in _upgrade_configs:
		_skill_levels[skill_id] = DEFAULT_LEVEL

	# 3. 从 SaveManager 恢复已保存的等级
	var section: Dictionary = SaveManager.get_section("skill_upgrades", SaveManager.DEFAULT_SECTIONS["skill_upgrades"])
	var saved_levels: Dictionary = section.get("skill_levels", {})
	for skill_id in saved_levels:
		if _skill_levels.has(skill_id):
			var saved_level: int = int(saved_levels[skill_id])
			var max_lv: int = _upgrade_configs[skill_id].max_level
			_skill_levels[skill_id] = clampi(saved_level, DEFAULT_LEVEL, max_lv)

	if DEBUG_MODE:
		print("[SkillUpgradeManager] 已加载升级配置: ", _upgrade_configs.size(), " 个技能")

## 功能：递归加载目录下的 .tres 资源
## 参数：dir_path (String) - 要加载的目录路径
func _recursive_load_configs(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		# 跳过隐藏文件
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path := dir_path.path_join(file_name)
		if dir.current_is_dir():
			# 递归加载子目录
			_recursive_load_configs(full_path)
		elif file_name.ends_with(".tres") or file_name.ends_with(".res"):
			# 加载资源并验证类型
			var res = load(full_path)
			if res is SkillUpgradeData and not res.skill_id.is_empty():
				_upgrade_configs[res.skill_id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

## 功能：将当前等级状态同步到 SaveManager 并保存
func _sync_to_save() -> void:
	SaveManager.set_section("skill_upgrades", {
		"skill_levels": _skill_levels.duplicate()
	})
	SaveManager.save_immediately()

# ========================== 公共查询 API ==========================
## 功能：获取技能当前等级
func get_skill_level(skill_id: String) -> int:
	return _skill_levels.get(skill_id, DEFAULT_LEVEL)

## 功能：获取技能最大等级
func get_max_level(skill_id: String) -> int:
	var config: SkillUpgradeData = _upgrade_configs.get(skill_id)
	if config == null:
		return DEFAULT_LEVEL
	return config.max_level

## 功能：获取下一级升级费用，已满级返回 -1
func get_upgrade_cost(skill_id: String) -> int:
	var config: SkillUpgradeData = _upgrade_configs.get(skill_id)
	if config == null:
		return -1
	var current_level: int = get_skill_level(skill_id)
	if current_level >= config.max_level:
		return -1
	var cost_index: int = current_level - 1  # index 0 = Lv1→Lv2
	if cost_index < config.upgrade_costs.size():
		return config.upgrade_costs[cost_index]
	return -1

## 功能：检查技能是否可以升级（已解锁 + 未满级 + 尘元足够）
func can_upgrade_skill(skill_id: String) -> bool:
	if not SkillUnlockManager.is_skill_unlocked(skill_id):
		return false
	var cost := get_upgrade_cost(skill_id)
	if cost < 0:
		return false
	return CurrencyManager.get_permanent_coin() >= cost

## 功能：获取技能的有效伤害值（含升级加成）
func get_effective_damage(skill_id: String, base_damage: float) -> float:
	var cum := get_cumulative_effect(skill_id)
	return base_damage * (1.0 + cum.get("damage_multiplier_bonus", 0.0))

## 功能：获取技能的有效倍率（含升级加成）
func get_effective_multiplier(skill_id: String, base_multiplier: float) -> float:
	var cum := get_cumulative_effect(skill_id)
	return base_multiplier * (1.0 + cum.get("damage_multiplier_bonus", 0.0))

## 功能：获取技能的有效冷却时间（含升级缩减）
func get_effective_cooldown(skill_id: String, base_cooldown: float) -> float:
	var cum := get_cumulative_effect(skill_id)
	return base_cooldown * (1.0 - cum.get("cooldown_reduction", 0.0))

## 功能：获取技能的有效能量消耗（含升级减少）
func get_effective_energy_cost(skill_id: String, base_cost: int) -> int:
	var cum := get_cumulative_effect(skill_id)
	return maxi(0, base_cost - cum.get("energy_cost_reduction", 0))

## 功能：获取技能到当前等级的累积升级效果
## 返回值：Dictionary - {"damage_multiplier_bonus": float, "cooldown_reduction": float, "energy_cost_reduction": int}
func get_cumulative_effect(skill_id: String) -> Dictionary:
	var result := {"damage_multiplier_bonus": 0.0, "cooldown_reduction": 0.0, "energy_cost_reduction": 0}
	var config: SkillUpgradeData = _upgrade_configs.get(skill_id)
	if config == null:
		return result
	var current_level: int = get_skill_level(skill_id)
	# 累积从 Lv2 到 current_level 的所有效果（index 0 = Lv2）
	for i in range(current_level - 1):
		if i < config.level_effects.size():
			var effect: SkillUpgradeEffect = config.level_effects[i]
			result["damage_multiplier_bonus"] += effect.damage_multiplier_bonus
			result["cooldown_reduction"] += effect.cooldown_reduction
			result["energy_cost_reduction"] += effect.energy_cost_reduction
	return result

# ========================== 公共操作 API ==========================
## 功能：升级技能（扣费 + 提升等级 + 持久化）
## 返回值：bool - true 表示升级成功
func upgrade_skill(skill_id: String) -> bool:
	var config: SkillUpgradeData = _upgrade_configs.get(skill_id)
	if config == null:
		push_warning("[SkillUpgradeManager] 尝试升级无配置的技能: ", skill_id)
		return false

	var current_level: int = get_skill_level(skill_id)
	if current_level >= config.max_level:
		if DEBUG_MODE:
			print("[SkillUpgradeManager] 技能已满级: ", skill_id)
		return false

	if not SkillUnlockManager.is_skill_unlocked(skill_id):
		push_warning("[SkillUpgradeManager] 尝试升级未解锁的技能: ", skill_id)
		return false

	var cost := get_upgrade_cost(skill_id)
	if cost < 0:
		return false

	if not CurrencyManager.spend_coin(cost):
		if DEBUG_MODE:
			print("[SkillUpgradeManager] 尘元不足，无法升级: ", skill_id, " (需要 ", cost, ")")
		return false

	# 提升等级
	var new_level: int = current_level + 1
	_skill_levels[skill_id] = new_level
	_sync_to_save()

	skill_upgraded.emit(skill_id, new_level)

	if DEBUG_MODE:
		print("[SkillUpgradeManager] 技能升级成功: ", skill_id, " → Lv.", new_level, " (花费 ", cost, " 尘元)")
	return true

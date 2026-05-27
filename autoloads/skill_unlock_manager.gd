# ==============================================================================
#   skill_unlock_manager.gd
#   功能：技能解锁状态管理器（Autoload 单例），管理技能的解锁/购买逻辑，
#        与 SaveManager 协作持久化解锁状态，与 CurrencyManager 协作完成扣费。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SkillUnlockManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 模块启用开关（后期系统，暂时禁用）
const ENABLED: bool = false
## 调试模式开关
const DEBUG_MODE: bool = true
## 默认解锁费用（未在费用表中单独配置的技能使用此值）
const DEFAULT_UNLOCK_COST: int = 50

## 技能解锁费用配置表（skill_id -> 费用）。费用为 0 的技能默认已解锁
const UNLOCK_COSTS: Dictionary = {
	"fireball_01": 0,
	"slash_fire_01": 0,
	"void_burst_skill_01": 0,
	"vortex_01": 0,
	"thornfire_01": 0,
}

# ========================== 信号声明模块 ==========================
## 触发时机：技能解锁状态发生变化时
## 参数：skill_id (String) - 技能 ID；is_unlocked (bool) - 新的解锁状态
signal skill_unlock_state_changed(skill_id: String, is_unlocked: bool)

## 触发时机：技能被成功购买解锁时
## 参数：skill_id (String) - 技能 ID；cost (int) - 消耗的尘元数量
signal skill_purchased(skill_id: String, cost: int)

# ========================== 内部变量模块 ==========================
## 技能解锁数据字典：{skill_id (String): SkillUnlockData}
var _unlock_data: Dictionary = {}

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	if not ENABLED:
		print("SkillUnlockManager: 已禁用")
		return
	SaveManager.data_loaded.connect(_on_save_data_loaded)
	print("SkillUnlockManager: 技能解锁管理器初始化完成")

# ========================== 存档集成模块 ==========================
## 功能：SaveManager 数据加载后，从 SkillLibrary 构建解锁数据并恢复已解锁状态
func _on_save_data_loaded() -> void:
	# 1. 从 SkillLibrary 构建所有技能的解锁数据
	_unlock_data.clear()
	var all_skills: Dictionary = SkillLibrary.get_all_skills()
	for skill_id in all_skills:
		var cost: int = UNLOCK_COSTS.get(skill_id, DEFAULT_UNLOCK_COST)
		# 费用为 0 的技能默认已解锁
		var unlocked: bool = cost == 0
		_unlock_data[skill_id] = SkillUnlockData.new(skill_id, cost, unlocked)

	# 2. 从 SaveManager 恢复已解锁状态（覆盖默认值）
	var section: Dictionary = SaveManager.get_section("skill_unlocks", SaveManager.DEFAULT_SECTIONS["skill_unlocks"])
	var saved_unlocked: Array = section.get("unlocked_skills", [])
	for skill_id in saved_unlocked:
		if _unlock_data.has(skill_id):
			_unlock_data[skill_id].is_unlocked = true

	if DEBUG_MODE:
		print("[SkillUnlockManager] 已加载解锁数据，技能总数: ", _unlock_data.size(), " | 已解锁: ", get_unlocked_skills().size())

## 功能：将当前解锁状态同步到 SaveManager 并保存
func _sync_to_save() -> void:
	var unlocked_ids: Array[String] = []
	for data in _unlock_data.values():
		if data.is_unlocked:
			unlocked_ids.append(data.skill_id)
	SaveManager.set_section("skill_unlocks", {
		"unlocked_skills": unlocked_ids
	})
	SaveManager.save_immediately()

# ========================== 公共查询 API ==========================
## 功能：查询技能是否已解锁
## 参数：skill_id (String) - 技能 ID
## 返回值：bool - true 表示已解锁
func is_skill_unlocked(skill_id: String) -> bool:
	var data: SkillUnlockData = _unlock_data.get(skill_id)
	if data == null:
		return false
	return data.is_unlocked

## 功能：查询技能是否可以解锁（检查尘元余额 + 前置技能）
## 参数：skill_id (String) - 技能 ID
## 返回值：bool - true 表示满足解锁条件
func can_unlock_skill(skill_id: String) -> bool:
	var data: SkillUnlockData = _unlock_data.get(skill_id)
	if data == null:
		return false
	# 已解锁则无需再次解锁
	if data.is_unlocked:
		return false
	# 检查尘元余额
	if CurrencyManager.get_permanent_coin() < data.unlock_cost:
		return false
	# 检查前置技能
	for prereq in data.prerequisite_skills:
		if not is_skill_unlocked(prereq):
			return false
	return true

## 功能：获取技能的解锁费用
## 参数：skill_id (String) - 技能 ID
## 返回值：int - 解锁费用，技能不存在时返回 -1
func get_unlock_cost(skill_id: String) -> int:
	var data: SkillUnlockData = _unlock_data.get(skill_id)
	if data == null:
		return -1
	return data.unlock_cost

## 功能：获取所有可解锁的技能 ID 列表（未解锁且满足前置条件）
## 返回值：Array[String] - 可解锁的技能 ID 数组
func get_unlockable_skills() -> Array[String]:
	var result: Array[String] = []
	for data in _unlock_data.values():
		if not data.is_unlocked and can_unlock_skill(data.skill_id):
			result.append(data.skill_id)
	return result

## 功能：获取所有已解锁的技能 ID 列表
## 返回值：Array[String] - 已解锁的技能 ID 数组
func get_unlocked_skills() -> Array[String]:
	var result: Array[String] = []
	for data in _unlock_data.values():
		if data.is_unlocked:
			result.append(data.skill_id)
	return result

## 功能：获取技能的解锁数据对象
## 参数：skill_id (String) - 技能 ID
## 返回值：SkillUnlockData - 解锁数据，不存在时返回 null
func get_unlock_data(skill_id: String) -> SkillUnlockData:
	return _unlock_data.get(skill_id)

# ========================== 公共操作 API ==========================
## 功能：解锁技能（扣费 + 更新状态 + 持久化）
## 参数：skill_id (String) - 技能 ID
## 返回值：bool - true 表示解锁成功
func unlock_skill(skill_id: String) -> bool:
	var data: SkillUnlockData = _unlock_data.get(skill_id)
	if data == null:
		push_warning("[SkillUnlockManager] 尝试解锁不存在的技能: ", skill_id)
		return false

	# 已解锁检查
	if data.is_unlocked:
		if DEBUG_MODE:
			print("[SkillUnlockManager] 技能已解锁，无需重复操作: ", skill_id)
		return false

	# 前置技能检查
	for prereq in data.prerequisite_skills:
		if not is_skill_unlocked(prereq):
			push_warning("[SkillUnlockManager] 前置技能未解锁: ", prereq)
			return false

	# 扣费
	if not CurrencyManager.spend_coin(data.unlock_cost):
		if DEBUG_MODE:
			print("[SkillUnlockManager] 尘元不足，无法解锁: ", skill_id, " (需要 ", data.unlock_cost, ")")
		return false

	# 更新状态
	data.is_unlocked = true
	_sync_to_save()

	# 发射信号
	skill_unlock_state_changed.emit(skill_id, true)
	skill_purchased.emit(skill_id, data.unlock_cost)

	if DEBUG_MODE:
		print("[SkillUnlockManager] 技能解锁成功: ", skill_id, " (花费 ", data.unlock_cost, " 尘元)")
	return true

## 功能：直接解锁技能（不扣费，用于BOSS掉落等场景）
## 参数：skill_id (String) - 技能 ID
## 返回值：bool - true 表示解锁成功
func unlock_skill_by_id(skill_id: String) -> bool:
	var data: SkillUnlockData = _unlock_data.get(skill_id)
	if data == null:
		# 如果技能不存在，创建一个临时数据（使用默认费用，无前置条件）
		data = SkillUnlockData.new(skill_id, DEFAULT_UNLOCK_COST, false)
		_unlock_data[skill_id] = data

	# 已解锁检查
	if data.is_unlocked:
		if DEBUG_MODE:
			print("[SkillUnlockManager] 技能已解锁，无需重复操作: ", skill_id)
		return false

	# 直接解锁（不扣费）
	data.is_unlocked = true
	_sync_to_save()

	# 发射信号
	skill_unlock_state_changed.emit(skill_id, true)

	if DEBUG_MODE:
		print("[SkillUnlockManager] 技能直接解锁成功: ", skill_id)
	return true

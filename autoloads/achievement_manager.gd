# ==============================================================================
#   achievement_manager.gd
#   功能：成就管理器（Autoload 单例），管理成就的解锁、进度追踪和奖励发放。
#        与 SaveManager 协作持久化成就状态。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 AchievementManager
# ==============================================================================
extends Node

# ========================== 常量 ==========================
## 成就资源目录
const ACHIEVEMENTS_DIR: String = "res://resources/data/achievements/"
## 调试模式开关
const DEBUG_MODE: bool = true

# ========================== 信号 ==========================
## 成就解锁时发射
signal achievement_unlocked(achievement_id: String)

## 成就进度更新时发射
signal achievement_progress_updated(achievement_id: String, current: int, target: int)

# ========================== 运行时状态 ==========================
## 已加载的成就数据 {achievement_id: AchievementData}
var _achievements: Dictionary = {}
## 已解锁的成就 ID 列表
var _unlocked: Array[String] = []
## 成就进度 {achievement_id: current_value}
var _progress: Dictionary = {}

# ========================== 生命周期 ==========================
func _ready() -> void:
	SaveManager.data_loaded.connect(_on_save_data_loaded)
	_connect_signals()
	print("AchievementManager: 成就管理器初始化完成")

# ========================== 存档集成 ==========================
func _on_save_data_loaded() -> void:
	_load_achievements()

	var section: Dictionary = SaveManager.get_section("achievements", _get_default_section())
	_unlocked = []
	for id in section.get("unlocked", []):
		if _achievements.has(id):
			_unlocked.append(id)

	_progress = {}
	var saved_progress: Dictionary = section.get("progress", {})
	for id in saved_progress:
		_progress[id] = saved_progress[id]

	if DEBUG_MODE:
		print("[AchievementManager] 已加载成就数据，成就总数: ", _achievements.size(), " | 已解锁: ", _unlocked.size())

func _get_default_section() -> Dictionary:
	return {
		"unlocked": [],
		"progress": {}
	}

func _sync_to_save() -> void:
	SaveManager.set_section("achievements", {
		"unlocked": _unlocked.duplicate(),
		"progress": _progress.duplicate()
	})
	SaveManager.save_immediately()

# ========================== 信号连接 ==========================
func _connect_signals() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.layer_advanced.connect(_on_layer_advanced)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.synergy_triggered.connect(_on_synergy_triggered)
	EventBus.weapon_upgraded.connect(_on_weapon_upgraded)
	EventBus.relic_acquired.connect(_on_relic_acquired)

# ========================== 公共 API ==========================
## 功能：检查成就是否已解锁
func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in _unlocked

## 功能：获取成就进度
func get_progress(achievement_id: String) -> int:
	return _progress.get(achievement_id, 0)

## 功能：获取所有成就数据
func get_all_achievements() -> Dictionary:
	return _achievements

## 功能：获取已解锁成就数量
func get_unlocked_count() -> int:
	return _unlocked.size()

## 功能：获取成就总数
func get_total_count() -> int:
	return _achievements.size()

## 功能：手动触发成就检查（用于特殊条件）
func check_achievement(achievement_id: String) -> void:
	var data: AchievementData = _achievements.get(achievement_id)
	if data == null or achievement_id in _unlocked:
		return
	_try_unlock(data)

## 功能：增加成就进度
func add_progress(achievement_id: String, amount: int = 1) -> void:
	var data: AchievementData = _achievements.get(achievement_id)
	if data == null or achievement_id in _unlocked:
		return

	var current: int = _progress.get(achievement_id, 0) + amount
	_progress[achievement_id] = current
	achievement_progress_updated.emit(achievement_id, current, data.condition_value)

	if current >= data.condition_value:
		_unlock_achievement(data)

# ========================== 内部方法 ==========================
## 功能：从资源目录加载所有成就数据
func _load_achievements() -> void:
	_achievements.clear()

	var dir := DirAccess.open(ACHIEVEMENTS_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(ACHIEVEMENTS_DIR + file_name)
			if resource is AchievementData:
				_achievements[resource.id] = resource
		file_name = dir.get_next()

## 功能：检查成就是否满足解锁条件（统一检查，无需按 condition_type 分支）
func _try_unlock(data: AchievementData) -> void:
	if _progress.get(data.id, 0) >= data.condition_value:
		_unlock_achievement(data)

## 功能：执行成就解锁（更新状态 + 持久化 + 发放奖励 + 发射信号）
func _unlock_achievement(data: AchievementData) -> void:
	if data.id in _unlocked:
		return

	_unlocked.append(data.id)
	_sync_to_save()

	# 发放奖励
	_grant_rewards(data)

	# 发射信号
	achievement_unlocked.emit(data.id)
	EventBus.achievement_unlocked.emit(data.id)

	if DEBUG_MODE:
		print("[AchievementManager] 成就解锁: ", data.display_name)

## 功能：发放成就解锁奖励
func _grant_rewards(data: AchievementData) -> void:
	# 金币奖励（直接增加永久货币）
	if data.reward_coins > 0:
		CurrencyManager.add_permanent_coin(data.reward_coins)

	# 遗物奖励
	if data.reward_relic is RelicData:
		RelicManager.acquire_relic(data.reward_relic)

	# 技能奖励（直接解锁，不扣费）
	if data.reward_skill is SkillEffect:
		SkillUnlockManager.unlock_skill_by_id(data.reward_skill.id)

# ========================== 信号回调 ==========================
## 功能：更新击杀类成就进度
func _on_enemy_killed(enemy_type: String, _coord: Vector2i) -> void:
	for data in _achievements.values():
		if data.condition_type == AchievementData.ConditionType.KILL_COUNT:
			if data.condition_target.is_empty() or data.condition_target == enemy_type:
				add_progress(data.id)

## 功能：更新 BOSS 击败类成就进度
func _on_boss_defeated(_coord: Vector2i, _layer: int) -> void:
	for data in _achievements.values():
		if data.condition_type == AchievementData.ConditionType.BOSS_DEFEAT:
			add_progress(data.id)

## 功能：更新层级到达类成就进度（取最大值，非累加）
func _on_layer_advanced(new_layer: int) -> void:
	for data in _achievements.values():
		if data.condition_type == AchievementData.ConditionType.LAYER_REACH:
			var old: int = _progress.get(data.id, 0)
			if new_layer > old:
				_progress[data.id] = new_layer
				achievement_progress_updated.emit(data.id, new_layer, data.condition_value)
				_try_unlock(data)

## 功能：运行结束时持久化成就数据
func _on_run_ended(_stats: Dictionary) -> void:
	_sync_to_save()

## 功能：更新协同触发类成就进度
func _on_synergy_triggered(_rule_id: String, _context: Dictionary) -> void:
	for data in _achievements.values():
		if data.condition_type == AchievementData.ConditionType.SYNERGY_COUNT:
			add_progress(data.id)

## 功能：更新武器升级类成就进度（取最大值，非累加）
func _on_weapon_upgraded(_weapon_id: String, new_level: int) -> void:
	for data in _achievements.values():
		if data.condition_type == AchievementData.ConditionType.WEAPON_UPGRADE:
			var old: int = _progress.get(data.id, 0)
			if new_level > old:
				_progress[data.id] = new_level
				achievement_progress_updated.emit(data.id, new_level, data.condition_value)
				_try_unlock(data)

## 功能：更新遗物收集类成就进度（以当前持有遗物数为准）
func _on_relic_acquired(_relic_id: String) -> void:
	for data in _achievements.values():
		if data.condition_type == AchievementData.ConditionType.RELIC_COUNT:
			var current_count: int = RelicManager.get_active_relics().size()
			_progress[data.id] = current_count
			achievement_progress_updated.emit(data.id, current_count, data.condition_value)
			_try_unlock(data)

# ==============================================================================
#   codex_manager.gd
#   功能：图鉴管理器（Autoload 单例），管理图鉴条目的解锁和查询。
#        与 SaveManager 协作持久化图鉴状态。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 CodexManager
# ==============================================================================
extends Node

# ========================== 常量 ==========================
## 图鉴资源目录
const CODEX_DIR: String = "res://resources/data/codex/"
## 调试模式开关
const DEBUG_MODE: bool = true

# ========================== 运行时状态 ==========================
## 已加载的图鉴条目 {entry_id: CodexEntry}
var _entries: Dictionary = {}
## 已解锁的条目 ID 列表
var _unlocked: Array[String] = []

# ========================== 生命周期 ==========================
func _ready() -> void:
	SaveManager.data_loaded.connect(_on_save_data_loaded)
	_connect_signals()
	print("CodexManager: 图鉴管理器初始化完成")

# ========================== 存档集成 ==========================
## 功能：存档加载后初始化图鉴数据并恢复解锁状态
func _on_save_data_loaded() -> void:
	_load_entries()

	var section: Dictionary = SaveManager.get_section("codex", _get_default_section())
	_unlocked = []
	for id in section.get("unlocked_entries", []):
		if _entries.has(id):
			_unlocked.append(id)

	if DEBUG_MODE:
		print("[CodexManager] 已加载图鉴数据，条目总数: ", _entries.size(), " | 已解锁: ", _unlocked.size())

## 功能：获取默认数据段
func _get_default_section() -> Dictionary:
	return {
		"unlocked_entries": []
	}

## 功能：将当前解锁状态同步到 SaveManager
func _sync_to_save() -> void:
	SaveManager.set_section("codex", {
		"unlocked_entries": _unlocked.duplicate()
	})
	SaveManager.save_immediately()

# ========================== 信号连接 ==========================
## 功能：连接 EventBus 信号
func _connect_signals() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.relic_acquired.connect(_on_relic_acquired)
	EventBus.weapon_equipped.connect(_on_weapon_equipped)
	EventBus.skill_slot_changed.connect(_on_skill_slot_changed)

# ========================== 公共 API ==========================
## 功能：检查条目是否已解锁
func is_unlocked(entry_id: String) -> bool:
	return entry_id in _unlocked

## 功能：获取所有图鉴条目
func get_all_entries() -> Dictionary:
	return _entries

## 功能：获取指定类型的图鉴条目
func get_entries_by_type(codex_type: CodexEntry.CodexType) -> Array[CodexEntry]:
	var result: Array[CodexEntry] = []
	for entry in _entries.values():
		if entry.codex_type == codex_type:
			result.append(entry)
	return result

## 功能：获取已解锁的图鉴条目
func get_unlocked_entries() -> Array[CodexEntry]:
	var result: Array[CodexEntry] = []
	for entry_id in _unlocked:
		if _entries.has(entry_id):
			result.append(_entries[entry_id])
	return result

## 功能：获取图鉴解锁进度
func get_progress() -> Dictionary:
	var total: int = _entries.size()
	var unlocked: int = _unlocked.size()
	var by_type: Dictionary = {}

	for type in CodexEntry.CodexType.values():
		var type_total: int = 0
		var type_unlocked: int = 0
		for entry in _entries.values():
			if entry.codex_type == type:
				type_total += 1
		for entry_id in _unlocked:
			if _entries.has(entry_id) and _entries[entry_id].codex_type == type:
				type_unlocked += 1
		by_type[type] = {"total": type_total, "unlocked": type_unlocked}

	return {"total": total, "unlocked": unlocked, "by_type": by_type}

## 功能：手动解锁图鉴条目
func unlock_entry(entry_id: String) -> bool:
	if entry_id in _unlocked:
		return false
	if not _entries.has(entry_id):
		push_warning("[CodexManager] 尝试解锁不存在的图鉴条目: ", entry_id)
		return false

	_unlocked.append(entry_id)
	_sync_to_save()
	EventBus.codex_entry_unlocked.emit(entry_id)

	if DEBUG_MODE:
		print("[CodexManager] 图鉴条目解锁: ", _entries[entry_id].display_name)
	return true

## 功能：获取指定类型的解锁数量
func get_unlocked_count_by_type(codex_type: CodexEntry.CodexType) -> int:
	var count: int = 0
	for entry_id in _unlocked:
		if _entries.has(entry_id) and _entries[entry_id].codex_type == codex_type:
			count += 1
	return count

## 功能：获取指定类型的总数量
func get_total_count_by_type(codex_type: CodexEntry.CodexType) -> int:
	var count: int = 0
	for entry in _entries.values():
		if entry.codex_type == codex_type:
			count += 1
	return count

# ========================== 内部方法 ==========================
## 功能：从资源目录加载所有图鉴条目
func _load_entries() -> void:
	_entries.clear()

	var dir := DirAccess.open(CODEX_DIR)
	if dir == null:
		push_warning("[CodexManager] 图鉴资源目录不存在: ", CODEX_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(CODEX_DIR + file_name)
			if resource is CodexEntry:
				_entries[resource.id] = resource
		file_name = dir.get_next()

# ========================== 信号回调 ==========================
## 功能：解锁敌人图鉴
func _on_enemy_killed(enemy_type: String, _coord: Vector2i) -> void:
	var entry_id: String = "enemy_" + enemy_type
	if _entries.has(entry_id) and entry_id not in _unlocked:
		unlock_entry(entry_id)

## 功能：解锁 BOSS 图鉴（按层级匹配 entry_id）
func _on_boss_defeated(_coord: Vector2i, layer: int) -> void:
	var entry_id: String = "boss_layer_%d" % layer
	if _entries.has(entry_id) and entry_id not in _unlocked:
		unlock_entry(entry_id)

## 功能：解锁遗物图鉴
func _on_relic_acquired(relic_id: String) -> void:
	var entry_id: String = "relic_" + relic_id
	if _entries.has(entry_id) and entry_id not in _unlocked:
		unlock_entry(entry_id)

## 功能：解锁武器图鉴
func _on_weapon_equipped(weapon_id: String) -> void:
	var entry_id: String = "weapon_" + weapon_id
	if _entries.has(entry_id) and entry_id not in _unlocked:
		unlock_entry(entry_id)

## 功能：解锁已装备技能的图鉴条目
func _on_skill_slot_changed(_slot_index: int) -> void:
	var player: Player = Global.player
	if player == null:
		return
	var equipped_ids: Array = player.skill_manager.get_equipped_ids()
	for skill_id in equipped_ids:
		var entry_id: String = "skill_" + skill_id
		if _entries.has(entry_id) and entry_id not in _unlocked:
			unlock_entry(entry_id)

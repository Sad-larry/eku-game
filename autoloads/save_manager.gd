# ==============================================================================
#   save_manager.gd
#   功能：存档管理器（Autoload 单例），管理游戏存档数据的读取、保存、更新。
#        使用 JSON 格式持久化，支持分段式数据架构（各 Manager 管理各自的数据段）。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SaveManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 存档文件存储路径（JSON 格式）
const SAVE_FILE_PATH: String = "user://ekugame_save.json"
## 存档版本号（用于未来格式迁移）
const SAVE_VERSION: int = 1
## 调试模式开关
const DEBUG_MODE: bool = true
## 默认数据段定义
## 各数据段用途说明：
##   settings    - 游戏设置（音量等）
##   statistics  - 统计信息（游戏时长、次数、总金币）
##   currency    - 永久货币（不会因游戏结束而重置）
##   skill_unlocks - 已解锁的技能列表
##   skill_upgrades - 各技能的等级
##   player_progression - 玩家等级等进度数据
const DEFAULT_SECTIONS: Dictionary = {
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.9,
		"ui_volume": 0.8
	},
	"statistics": {
		"play_time": 0,
		"games_played": 0,
		"lifetime_coin": 0
	},
	"currency": {
		"permanent_coin": 0
	},
	"skill_unlocks": {
		"unlocked_skills": []
	},
	"skill_upgrades": {
		"skill_levels": {}
	},
	"player_progression": {
		"player_level": 1
	},
	"active_run": {
		"has_active_run": false,
		"world_seed": 0,
		"current_layer": 1,
		"current_coord": {"x": 0, "y": 0},
		"player_health_pct": 1.0,
		"player_energy_pct": 1.0,
		"current_coin": 0,
		"room_states": {},
		"elapsed_time": 0.0,
		"boss_defeated": false
	},
	"meta_progression": {
		"total_runs": 0,
		"total_bosses_defeated": 0,
		"max_layer_reached": 0,
		"best_run_time": -1,
		"total_enemies_killed": 0,
		"total_rooms_cleared": 0
	},
	"boss_defeats": {
		"defeated_bosses": {},
		"first_clear_claimed": []
	},
	"weapons": {
		"owned_weapons": [],
		"equipped_weapon": "",
		"weapon_levels": {},
		"weapon_enchants": {}
	},
	"achievements": {
		"unlocked": [],
		"progress": {}
	},
	"codex": {
		"unlocked_entries": []
	}
}

# ========================== 信号声明模块 ==========================
## 存档数据从磁盘加载完成后发射
signal data_loaded()
## 存档数据写入磁盘完成后发射
signal data_saved()

# ========================== 内部变量模块 ==========================
## 根数据字典（所有数据段的容器）
var _root: Dictionary = {}
## 浮点累加器（用于游戏时间统计）
var _pending_play_time: float = 0.0

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时加载存档数据，注册窗口关闭回调
func _ready() -> void:
	get_tree().auto_accept_quit = false
	load_save_data()
	# 延迟到下一帧发射信号，确保所有 Autoload 已完成 _ready() 并连接了 data_loaded
	call_deferred("_notify_data_loaded")
	print("SaveManager: 存档管理器初始化完成（JSON 格式）")

## 功能：延迟通知数据已加载（在所有 Autoload 初始化完成后执行）
func _notify_data_loaded() -> void:
	data_loaded.emit()
	if DEBUG_MODE:
		print("[SaveManager] data_loaded 信号已发射")

## 功能：捕获窗口关闭事件，确保退出前保存
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_to_disk()
		get_tree().quit()

# ========================== 核心存档操作模块 ==========================
## 功能：从磁盘加载存档数据（JSON 格式）
## 说明：损坏文件自动恢复为默认数据，缺失字段自动填充默认值
func load_save_data() -> void:
	# 加载 JSON 文件
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK and json.data is Dictionary:
			_root = _merge_with_defaults(json.data)
		else:
			push_warning("[SaveManager] 存档文件损坏，使用默认数据")
			_root = _get_default_root()
			flush_to_disk()
	else:
		# 文件不存在，创建默认存档
		_root = _get_default_root()
		flush_to_disk()

	# 版本迁移检查
	if _root.get("version", 0) < SAVE_VERSION:
		_migrate_version(_root["version"])
		flush_to_disk()

	if DEBUG_MODE:
		print("[SaveManager] 存档数据已加载，版本: ", _root.get("version", 0))

## 功能：将当前内存数据写入磁盘（JSON 格式）
func flush_to_disk() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(_root, "\t")
		file.store_string(json_string)
		file.close()
		data_saved.emit()
		if DEBUG_MODE:
			print("[SaveManager] 存档数据已保存到磁盘")
	else:
		push_error("[SaveManager] 无法打开存档文件进行写入")

## 功能：立即保存（使用 call_deferred 避免递归调用）
func save_immediately() -> void:
	call_deferred("flush_to_disk")

# ========================== 分段式数据 API ==========================
## 功能：获取一个数据段的深拷贝。若段不存在，返回 default 的深拷贝
## 参数：section_key (String) - 数据段键名；default (Dictionary) - 默认值
## 返回值：Dictionary - 数据段的深拷贝
func get_section(section_key: String, default: Dictionary = {}) -> Dictionary:
	if _root.has(section_key) and _root[section_key] is Dictionary:
		return _root[section_key].duplicate(true)
	return default.duplicate(true)

## 功能：写入一个数据段（深拷贝存储，防止外部引用污染）
## 参数：section_key (String) - 数据段键名；data (Dictionary) - 数据
func set_section(section_key: String, data: Dictionary) -> void:
	_root[section_key] = data.duplicate(true)

# ========================== 便捷查询模块 ==========================
## 功能：检查存档文件是否存在
## 返回值：bool - true 表示存在
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

## 功能：获取存档版本号
## 返回值：int - 当前存档版本
func get_save_version() -> int:
	return _root.get("version", 0)

# ========================== 便捷操作 API ==========================
## 功能：增加游戏次数（每次开始新游戏时调用）
func increment_games_played() -> void:
	var stats = get_section("statistics", DEFAULT_SECTIONS["statistics"])
	stats["games_played"] += 1
	set_section("statistics", stats)
	save_immediately()

## 功能：累加游戏时间
## 参数：seconds (float) - 本次增加的秒数（通常为每帧 delta 累积）
func add_play_time(seconds: float) -> void:
	_pending_play_time += seconds
	if _pending_play_time >= 1.0:
		var stats = get_section("statistics", DEFAULT_SECTIONS["statistics"])
		stats["play_time"] += int(_pending_play_time)
		_pending_play_time = fmod(_pending_play_time, 1.0)
		set_section("statistics", stats)
		save_immediately()

## 功能：获取格式化的总游戏时间（HH:MM:SS 格式）
## 返回值：String - 格式化的时间字符串
func get_formatted_play_time() -> String:
	var stats = get_section("statistics", DEFAULT_SECTIONS["statistics"])
	var total_seconds: int = stats.get("play_time", 0)
	var hours: int = int(float(total_seconds) / 3600)
	var minutes: int = int(float(total_seconds % 3600) / 60)
	var seconds: int = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# ========================== 重置与删除模块 ==========================
## 功能：重置所有存档数据为默认值并立即写入磁盘（仅调试模式使用）
func reset_save_data() -> void:
	_root = _get_default_root()
	flush_to_disk()
	if DEBUG_MODE:
		print("[SaveManager] 存档数据已重置为默认值")

## 功能：删除存档文件
func delete_save_file() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		if DEBUG_MODE:
			print("[SaveManager] 存档文件已删除")
	_root = _get_default_root()

# ========================== 内部工具函数 ==========================
## 功能：生成默认的根数据字典（所有段的深拷贝）
## 返回值：Dictionary - 包含所有默认数据段的根字典
func _get_default_root() -> Dictionary:
	var root := {"version": SAVE_VERSION}
	for key in DEFAULT_SECTIONS:
		root[key] = DEFAULT_SECTIONS[key].duplicate(true)
	return root

## 功能：将加载的数据与默认值合并（保留已有值，填充缺失字段）
## 参数：loaded (Dictionary) - 从磁盘加载的数据
## 返回值：Dictionary - 合并后的完整数据
func _merge_with_defaults(loaded: Dictionary) -> Dictionary:
	var root := _get_default_root()
	for key in loaded:
		if root.has(key) and root[key] is Dictionary and loaded[key] is Dictionary:
			# 深度合并：加载的值覆盖默认值，但保留新版本新增的默认键
			for sub_key in loaded[key]:
				root[key][sub_key] = loaded[key][sub_key]
		else:
			root[key] = loaded[key]
	return root

## 功能：版本迁移钩子（处理存档格式变更）
## 参数：old_version (int) - 旧存档版本号
func _migrate_version(old_version: int) -> void:
	if DEBUG_MODE:
		print("[SaveManager] 存档版本迁移: ", old_version, " -> ", SAVE_VERSION)
	# 未来版本迁移逻辑在此添加（match old_version）
	_root["version"] = SAVE_VERSION

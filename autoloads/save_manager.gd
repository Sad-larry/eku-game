# autoloads/save_manager.gd
# 存档管理器：管理游戏存档数据，包括最高连击数等基础数据
# 自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SaveManager
extends Node

# ========================== 常量定义 ==========================
const SAVE_FILE_PATH: String = "user://ekugame_save.dat"

# ========================== 存档数据结构 ==========================
var save_data: Dictionary = {
	"high_score": 0,           # 最高分数
	"max_combo": 0,            # 最高连击数
	"play_time": 0,            # 总游戏时间（秒）
	"games_played": 0,         # 游戏次数
	"last_session": {}         # 上次会话数据（预留）
}

# ========================== 初始化 ==========================
func _ready() -> void:
	load_save_data()
	print("SaveManager: 存档管理器初始化完成")

# ========================== 存档操作 ==========================
## 加载存档数据
func load_save_data() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		if loaded_data is Dictionary:
			# 合并加载的数据，保留默认值用于新字段
			for key in save_data:
				if loaded_data.has(key):
					save_data[key] = loaded_data[key]
		file.close()
	else:
		# 文件不存在，创建默认存档
		save_save_data()

## 保存存档数据
func save_save_data() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[SaveManager] 存档数据已保存")
	else:
		push_error("[SaveManager] 无法打开存档文件进行写入")

## 立即保存（安全版本）
func save_immediately() -> void:
	call_deferred("save_save_data")

# ========================== 数据访问接口 ==========================
## 更新最高连击数
func update_max_combo(new_combo: int) -> bool:
	if new_combo > save_data["max_combo"]:
		save_data["max_combo"] = new_combo
		save_immediately()
		print("[SaveManager] 最高连击数更新 -> ", new_combo)
		return true
	return false

## 获取最高连击数
func get_max_combo() -> int:
	return save_data["max_combo"]

## 增加游戏次数
func increment_games_played() -> void:
	save_data["games_played"] += 1
	save_immediately()

## 更新游戏时间
func add_play_time(seconds: float) -> void:
	save_data["play_time"] += int(seconds)
	# 不立即保存，避免频繁写入

## 更新最高分数
func update_high_score(new_score: int) -> bool:
	if new_score > save_data["high_score"]:
		save_data["high_score"] = new_score
		save_immediately()
		return true
	return false

## 获取最高分数
func get_high_score() -> int:
	return save_data["high_score"]

## 获取总游戏时间（格式化）
func get_formatted_play_time() -> String:
	var total_seconds = save_data["play_time"]
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# ========================== 调试与重置 ==========================
## 重置存档数据（调试用）
func reset_save_data() -> void:
	save_data = {
		"high_score": 0,
		"max_combo": 0,
		"play_time": 0,
		"games_played": 0,
		"last_session": {}
	}
	save_save_data()
	print("[SaveManager] 存档数据已重置")

## 打印存档状态（调试用）
func print_save_status() -> void:
	print("=== 存档状态 ===")
	print("最高分数: ", save_data["high_score"])
	print("最高连击数: ", save_data["max_combo"])
	print("游戏时间: ", get_formatted_play_time())
	print("游戏次数: ", save_data["games_played"])
	print("================")

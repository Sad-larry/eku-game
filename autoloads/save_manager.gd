# ==============================================================================
#   save_manager.gd
#   功能：存档管理器（Autoload 单例），管理游戏存档数据的读取、保存、更新，
#        支持总游戏时间、游戏次数等基础数据的持久化存储。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SaveManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 存档文件存储路径（user:// 为 Godot 的用户数据目录）
const SAVE_FILE_PATH: String = "user://ekugame_save.dat"

# ========================== 变量定义模块 ==========================
## 存档数据结构，包含游戏统计信息
var save_data: Dictionary = {
	"play_time": 0,            # 总游戏时间（秒）
	"games_played": 0,         # 累计游戏次数
	"last_session": {}         # 上次会话数据（预留，用于断线重连或临时状态保存）
}

## 浮点累加器
var _pending_play_time: float = 0.0
# ========================== 生命周期模块 ==========================
## 功能：节点就绪时加载存档数据
func _ready() -> void:
	load_save_data()
	print("SaveManager: 存档管理器初始化完成")

# ========================== 存档操作模块 ==========================
## 功能：从磁盘加载存档数据
## 说明：若存档文件不存在则创建默认存档；若存在则合并加载的数据与默认结构（保留新字段）
func load_save_data() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		if loaded_data is Dictionary:
			# 合并加载的数据，保留默认值用于新字段（防止版本升级时字段缺失）
			for key in save_data:
				if loaded_data.has(key):
					save_data[key] = loaded_data[key]
		file.close()
	else:
		# 文件不存在，创建默认存档
		flush_to_disk()

## 功能：将存档数据保存到磁盘
func flush_to_disk() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[SaveManager] 存档数据已保存")
	else:
		push_error("[SaveManager] 无法打开存档文件进行写入")

## 功能：立即保存（安全版本，使用 call_deferred 避免递归）
func save_immediately() -> void:
	call_deferred("flush_to_disk")

# ========================== 数据访问接口模块 ==========================
## 功能：增加游戏次数（每次开始新游戏时调用）
func increment_games_played() -> void:
	save_data["games_played"] += 1
	save_immediately()

## 功能：累加游戏时间
## 参数：seconds (float) - 本次增加的秒数（通常为每帧 delta 累积）
## 说明：为性能考虑，不立即保存，避免频繁磁盘写入
func add_play_time(seconds: float) -> void:
	_pending_play_time += seconds
	if _pending_play_time >= 1.0:
		save_data["play_time"] += int(_pending_play_time)
		_pending_play_time = fmod(_pending_play_time, 1.0)

## 功能：获取格式化的总游戏时间（HH:MM:SS 格式）
## 返回值：String - 格式化的时间字符串，如 "01:23:45"
func get_formatted_play_time() -> String:
	var total_seconds = save_data["play_time"]
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# ========================== 调试与重置模块 ==========================
## 功能：重置存档数据为默认值（仅调试模式使用）
## 说明：会立即覆盖存档文件，请谨慎调用
func reset_save_data() -> void:
	save_data = {
		"play_time": 0,
		"games_played": 0,
		"last_session": {}
	}
	flush_to_disk()
	print("[SaveManager] 存档数据已重置")

# ==============================================================================
#   run_manager.gd
#   功能：运行生命周期管理器（Autoload 单例），管理单次冒险运行的完整生命周期。
#        跟踪运行状态、当前层数、世界种子，提供检查点保存/恢复、运行统计、
#        Meta 进度持久化等功能。与 SaveManager 协作持久化数据。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 RunManager
# ==============================================================================
extends Node

# ========================== 枚举定义模块 ==========================
## 运行状态枚举
enum RunStatus {
	NONE,        ## 无运行（大厅状态）
	IN_PROGRESS, ## 运行进行中
	PAUSED,      ## 运行暂停（保存并退出）
	COMPLETED,   ## 运行完成（通关）
	FAILED,      ## 运行失败（死亡）
}

# ========================== 信号声明模块 ==========================
## 触发时机：新运行开始时
## 参数：seed (int) - 世界种子；layer (int) - 起始层数
signal run_started(seed: int, layer: int)

## 触发时机：运行结束时（死亡或主动放弃）
## 参数：stats (Dictionary) - 本次运行统计
signal run_ended(stats: Dictionary)

## 触发时机：层数推进时
## 参数：new_layer (int) - 新层数
signal layer_advanced(new_layer: int)

## 触发时机：敌人被击杀时（用于统计追踪）
## 参数：enemy_type (String) - 敌人类型；coord (Vector2i) - 所在房间坐标
signal enemy_killed(enemy_type: String, coord: Vector2i)

## 触发时机：运行检查点保存时
signal checkpoint_saved()

# ========================== 常量定义模块 ==========================
## 调试模式开关
const DEBUG_MODE: bool = true

# ========================== 运行状态变量模块 ==========================
## 当前运行状态
var run_status: RunStatus = RunStatus.NONE
## 当前层数（从 1 开始）
var current_layer: int = 1
## 本次运行的世界种子
var run_seed: int = 0
## 运行开始的 Unix 时间戳
var run_start_time: int = 0
## 运行累计用时（秒，暂停时不计）
var run_elapsed_time: float = 0.0
## 当前层 Boss 是否已击败
var _boss_defeated: bool = false

# ========================== 运行统计变量模块 ==========================
## 本次运行统计
var _run_stats: Dictionary = {}

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时连接信号
func _ready() -> void:
	# 初始化运行统计
	_reset_run_stats()
	# 监听运行结束信号，自动记录 Meta 进度
	run_ended.connect(_on_run_ended)
	# 监听敌人击杀信号，自动更新统计
	enemy_killed.connect(_on_enemy_killed)
	# 监听房间清除信号，自动更新统计
	RoomManager.room_cleared.connect(_on_room_cleared)
	# 监听连击数更新，追踪最大连击
	EventBus.combo_updated.connect(_on_combo_updated)
	# 监听金币收集，追踪金币统计
	CurrencyManager.coin_collected.connect(_on_coin_collected)
	# 监听 Boss 击败，记录当前层 Boss 状态
	EventBus.boss_defeated.connect(_on_boss_defeated)
	print("RunManager: 运行管理器初始化完成")

## 功能：每帧累加运行用时
func _process(delta: float) -> void:
	if run_status == RunStatus.IN_PROGRESS:
		run_elapsed_time += delta
		_run_stats["elapsed_time"] = run_elapsed_time

# ========================== 运行生命周期 API ==========================
## 功能：开始新运行
## 参数：seed_value (int) - 世界种子（0 表示随机生成）
func start_new_run(seed_value: int = 0) -> void:
	# 清理上一次运行的残留状态
	if run_status != RunStatus.NONE:
		cleanup_run_state()

	run_seed = seed_value if seed_value != 0 else randi()
	current_layer = 1
	run_start_time = int(Time.get_unix_time_from_system())
	run_elapsed_time = 0.0
	run_status = RunStatus.IN_PROGRESS

	# 重置运行统计
	_reset_run_stats()

	# 增加游戏次数
	SaveManager.increment_games_played()

	run_started.emit(run_seed, current_layer)
	if DEBUG_MODE:
		print("[RunManager] 新运行开始 | 种子: ", run_seed, " | 层数: ", current_layer)

## 功能：结束运行
## 参数：outcome (RunStatus) - 运行结果（COMPLETED 或 FAILED）
##       cause (String) - 死亡原因（仅 FAILED 时有效）
func end_run(outcome: RunStatus, cause: String = "") -> void:
	if run_status != RunStatus.IN_PROGRESS:
		return

	run_status = outcome
	_run_stats["elapsed_time"] = run_elapsed_time
	_run_stats["layer_reached"] = current_layer
	if cause != "":
		_run_stats["cause_of_death"] = cause

	# 清除检查点
	clear_checkpoint()

	run_ended.emit(_run_stats.duplicate())
	if DEBUG_MODE:
		print("[RunManager] 运行结束 | 结果: ", RunStatus.keys()[outcome], " | 用时: ", _format_time(run_elapsed_time))

## 功能：暂停运行（保存并退出）
func pause_run() -> void:
	if run_status != RunStatus.IN_PROGRESS:
		return
	run_status = RunStatus.PAUSED
	save_checkpoint()
	if DEBUG_MODE:
		print("[RunManager] 运行已暂停并保存检查点")

## 功能：恢复运行（从暂停状态恢复）
func resume_run() -> void:
	if run_status != RunStatus.PAUSED:
		return
	run_status = RunStatus.IN_PROGRESS
	if DEBUG_MODE:
		print("[RunManager] 运行已恢复")

## 功能：查询是否有进行中的运行
## 返回值：bool - true 表示有活跃运行
func is_run_active() -> bool:
	return run_status == RunStatus.IN_PROGRESS or run_status == RunStatus.PAUSED

# ========================== 层数管理 API ==========================
## 功能：推进到下一层
func advance_layer() -> void:
	current_layer += 1
	_boss_defeated = false
	_run_stats["layer_reached"] = current_layer
	layer_advanced.emit(current_layer)
	if DEBUG_MODE:
		print("[RunManager] 层数推进 -> ", current_layer)

# ========================== 统计记录 API ==========================
## 功能：记录造成伤害
func record_damage_dealt(amount: int) -> void:
	_run_stats["damage_dealt"] += amount

## 功能：记录受到伤害
func record_damage_taken(amount: int) -> void:
	_run_stats["damage_taken"] += amount

## 功能：获取当前运行统计
## 返回值：Dictionary - 统计数据的深拷贝
func get_run_stats() -> Dictionary:
	return _run_stats.duplicate()

## 功能：获取格式化的运行用时
## 返回值：String - HH:MM:SS 格式
func get_formatted_time() -> String:
	return _format_time(run_elapsed_time)

# ========================== 检查点 API ==========================
## 功能：保存当前运行状态到 SaveManager
func save_checkpoint() -> void:
	var player := Global.player
	var checkpoint_data := {
		"has_active_run": true,
		"world_seed": run_seed,
		"current_layer": current_layer,
		"current_coord": _get_current_coord_dict(),
		"player_health_pct": _get_player_health_pct(player),
		"player_energy_pct": _get_player_energy_pct(player),
		"current_coin": CurrencyManager.get_current_coin(),
		"room_states": _serialize_room_states(),
		"elapsed_time": run_elapsed_time,
		"boss_defeated": _is_boss_defeated(),
	}
	SaveManager.set_section("active_run", checkpoint_data)
	SaveManager.save_immediately()
	checkpoint_saved.emit()
	if DEBUG_MODE:
		print("[RunManager] 检查点已保存")

## 功能：检查是否有中断的运行
## 返回值：bool - true 表示有可恢复的运行
func has_interrupted_run() -> bool:
	var data := SaveManager.get_section("active_run", {})
	return data.get("has_active_run", false)

## 功能：从检查点恢复运行数据
## 返回值：Dictionary - 检查点数据
func restore_from_checkpoint() -> Dictionary:
	var data := SaveManager.get_section("active_run", {})
	if not data.get("has_active_run", false):
		return {}

	run_seed = data.get("world_seed", 0)
	current_layer = data.get("current_layer", 1)
	run_elapsed_time = data.get("elapsed_time", 0.0)
	run_status = RunStatus.IN_PROGRESS

	# 恢复房间状态
	_restore_room_states(data.get("room_states", {}))

	# 恢复货币
	var saved_coin: int = data.get("current_coin", 0)
	CurrencyManager.reset_current()
	if saved_coin > 0:
		CurrencyManager.add_coin(saved_coin)

	run_started.emit(run_seed, current_layer)
	if DEBUG_MODE:
		print("[RunManager] 从检查点恢复 | 种子: ", run_seed, " | 层数: ", current_layer)
	return data

## 功能：清除检查点
func clear_checkpoint() -> void:
	SaveManager.set_section("active_run", {"has_active_run": false})
	SaveManager.save_immediately()

# ========================== 状态清理 API ==========================
## 功能：统一清理所有运行时状态
func cleanup_run_state() -> void:
	RoomManager.reset_all()
	run_status = RunStatus.NONE
	current_layer = 1
	run_seed = 0
	run_elapsed_time = 0.0
	_boss_defeated = false
	_reset_run_stats()
	clear_checkpoint()
	if DEBUG_MODE:
		print("[RunManager] 运行状态已清理")

# ========================== 内部回调模块 ==========================
## 功能：运行结束时记录 Meta 进度
func _on_run_ended(stats: Dictionary) -> void:
	_save_meta_progression(stats)

## 功能：敌人击杀回调
func _on_enemy_killed(_enemy_type: String, _coord: Vector2i) -> void:
	_run_stats["enemies_killed"] += 1

## 功能：房间清除回调
func _on_room_cleared(_coord: Vector2i) -> void:
	_run_stats["rooms_cleared"] += 1

## 功能：连击数更新回调
func _on_combo_updated(new_combo: int) -> void:
	if new_combo > _run_stats["max_combo"]:
		_run_stats["max_combo"] = new_combo

## 功能：金币收集回调
func _on_coin_collected(amount: int) -> void:
	_run_stats["coins_collected"] += amount

## 功能：Boss 击败回调
## 参数：_coord (Vector2i) - Boss 房间坐标；_layer (int) - 当前层数
func _on_boss_defeated(_coord: Vector2i, _layer: int) -> void:
	_boss_defeated = true
	_run_stats["bosses_defeated"] += 1

# ========================== Meta 进度模块 ==========================
## 功能：将运行统计合并到 Meta 进度
func _save_meta_progression(stats: Dictionary) -> void:
	var meta := SaveManager.get_section("meta_progression", _get_default_meta())
	meta["total_runs"] += 1
	meta["total_enemies_killed"] += stats.get("enemies_killed", 0)
	meta["total_rooms_cleared"] += stats.get("rooms_cleared", 0)

	var layer_reached: int = stats.get("layer_reached", 1)
	if layer_reached > meta["max_layer_reached"]:
		meta["max_layer_reached"] = layer_reached

	if run_status == RunStatus.COMPLETED:
		meta["total_bosses_defeated"] += stats.get("bosses_defeated", 0)
		var elapsed: float = stats.get("elapsed_time", 0.0)
		if meta["best_run_time"] < 0 or elapsed < meta["best_run_time"]:
			meta["best_run_time"] = elapsed

	SaveManager.set_section("meta_progression", meta)
	SaveManager.save_immediately()
	if DEBUG_MODE:
		print("[RunManager] Meta 进度已更新")

## 功能：获取默认 Meta 进度数据
func _get_default_meta() -> Dictionary:
	return {
		"total_runs": 0,
		"total_bosses_defeated": 0,
		"max_layer_reached": 0,
		"best_run_time": -1,
		"total_enemies_killed": 0,
		"total_rooms_cleared": 0,
	}

# ========================== 工具方法模块 ==========================
## 功能：重置运行统计
func _reset_run_stats() -> void:
	_run_stats = {
		"enemies_killed": 0,
		"rooms_cleared": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"coins_collected": 0,
		"max_combo": 0,
		"elapsed_time": 0.0,
		"layer_reached": 1,
		"bosses_defeated": 0,
		"cause_of_death": "",
	}

## 功能：格式化时间为 HH:MM:SS
func _format_time(total_seconds: float) -> String:
	var secs :int = int(total_seconds)
	var hours :int = int(float(secs) / 3600)
	var minutes :int = int(float((secs % 3600)) / 60)
	var seconds := secs % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

## 功能：获取当前玩家所在的房间坐标
func _get_current_coord_dict() -> Dictionary:
	return {"x": RoomManager.current_coord.x, "y": RoomManager.current_coord.y}

## 功能：获取玩家血量百分比
func _get_player_health_pct(player: Player) -> float:
	if player and is_instance_valid(player) and player.health_component:
		return float(player.health_component.current_health) / float(player.health_component.max_health)
	return 1.0

## 功能：获取玩家能量百分比
func _get_player_energy_pct(player: Player) -> float:
	if player and is_instance_valid(player) and player.energy_component:
		return float(player.energy_component.current_energy) / float(player.energy_component.max_energy)
	return 1.0

## 功能：序列化房间状态为可存储格式
func _serialize_room_states() -> Dictionary:
	var result := {}
	# RoomManager._room_states 是 Dictionary，key="x,y" -> RoomState
	for key in RoomManager._room_states:
		result[key] = RoomManager._room_states[key]
	return result

## 功能：检查当前层 Boss 是否已击败
## 返回值：bool - true 表示 Boss 已击败
func _is_boss_defeated() -> bool:
	return _boss_defeated

## 功能：从序列化数据恢复房间状态
func _restore_room_states(data: Dictionary) -> void:
	RoomManager.reset_all()
	for key in data:
		var parts :Array = key.split(",")
		if parts.size() == 2:
			var coord := Vector2i(parts[0].to_int(), parts[1].to_int())
			var state: int = data[key]
			RoomManager.set_state(coord, state)

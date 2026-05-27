# ==============================================================================
#   analytics_manager.gd
#   功能：数据分析管理器（Autoload 单例），追踪玩家行为数据、收集平衡性指标。
#        运行结束时将数据写入日志文件，供外部工具分析。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 AnalyticsManager
# ==============================================================================
extends Node

# ========================== 常量 ==========================
## 模块启用开关（后期系统，暂时禁用）
const ENABLED: bool = false
## 分析数据输出目录
const ANALYTICS_DIR: String = "user://analytics/"
## 调试模式开关
const DEBUG_MODE: bool = true

# ========================== 运行时状态 ==========================
## 本次运行的数据收集
var _run_data: Dictionary = {}
## 技能使用频率 {skill_id: count}
var _skill_usage: Dictionary = {}
## 技能伤害统计 {skill_id: {total_damage, hit_count, crit_count}}
var _skill_damage_stats: Dictionary = {}
## 协同触发频率 {rule_id: count}
var _synergy_triggers: Dictionary = {}
## 敌人击杀统计 {enemy_type: count}
var _enemy_kills: Dictionary = {}
## BOSS挑战数据 {boss_id: {attempts, defeats}}
var _boss_data: Dictionary = {}
## 武器使用率 {weapon_id: usage_time}
var _weapon_usage: Dictionary = {}
## 金币经济数据 {earned, spent}
var _coin_data: Dictionary = {}
## 死亡原因统计
var _death_causes: Dictionary = {}
## 运行时长
var _run_start_time: float = 0.0

# ========================== 生命周期 ==========================
func _ready() -> void:
	if not ENABLED:
		print("AnalyticsManager: 已禁用")
		return
	_connect_signals()
	print("AnalyticsManager: 数据分析管理器初始化完成")

func _connect_signals() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.synergy_triggered.connect(_on_synergy_triggered)
	EventBus.weapon_equipped.connect(_on_weapon_equipped)
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.shop_item_purchased.connect(_on_shop_item_purchased)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)

# ========================== 公共 API ==========================
## 功能：获取本次运行的数据快照
func get_run_snapshot() -> Dictionary:
	return _run_data.duplicate(true)

## 功能：获取技能使用频率
func get_skill_usage() -> Dictionary:
	return _skill_usage.duplicate()

## 功能：获取技能伤害统计
func get_skill_damage_stats() -> Dictionary:
	return _skill_damage_stats.duplicate(true)

## 功能：获取协同触发频率
func get_synergy_triggers() -> Dictionary:
	return _synergy_triggers.duplicate()

## 功能：获取敌人击杀统计
func get_enemy_kills() -> Dictionary:
	return _enemy_kills.duplicate()

## 功能：重置运行时状态
func reset_run_state() -> void:
	_run_data.clear()
	_skill_usage.clear()
	_skill_damage_stats.clear()
	_synergy_triggers.clear()
	_enemy_kills.clear()
	_boss_data.clear()
	_weapon_usage.clear()
	_coin_data = {"earned": 0, "spent": 0}
	_death_causes.clear()
	_run_start_time = 0.0

# ========================== 信号回调 ==========================
## 功能：运行开始时重置数据并记录起始信息
func _on_run_started(_seed: int, _layer: int) -> void:
	reset_run_state()
	_run_start_time = Time.get_unix_time_from_system()
	_run_data["start_time"] = _run_start_time
	_run_data["seed"] = _seed
	_run_data["start_layer"] = _layer

## 功能：运行结束时汇总数据并写入分析文件
func _on_run_ended(stats: Dictionary) -> void:
	_run_data["end_time"] = Time.get_unix_time_from_system()
	_run_data["duration"] = _run_data["end_time"] - _run_start_time
	_run_data["stats"] = stats
	_run_data["skill_usage"] = _skill_usage.duplicate()
	_run_data["skill_damage_stats"] = _skill_damage_stats.duplicate(true)
	_run_data["synergy_triggers"] = _synergy_triggers.duplicate()
	_run_data["enemy_kills"] = _enemy_kills.duplicate()
	_run_data["boss_data"] = _boss_data.duplicate(true)
	_run_data["weapon_usage"] = _weapon_usage.duplicate()
	_run_data["coin_data"] = _coin_data.duplicate()
	_run_data["death_causes"] = _death_causes.duplicate()

	# 写入文件
	_write_analytics_file()

	if DEBUG_MODE:
		print("[AnalyticsManager] 运行数据已记录")

## 功能：记录伤害事件，更新技能使用频率和伤害统计
func _on_damage_dealt(info: DamageInfo) -> void:
	if info.skill_data == null:
		return

	var skill_id: String = info.skill_data.id

	# 更新技能使用频率
	_skill_usage[skill_id] = _skill_usage.get(skill_id, 0) + 1

	# 更新技能伤害统计
	if not _skill_damage_stats.has(skill_id):
		_skill_damage_stats[skill_id] = {"total_damage": 0.0, "hit_count": 0, "crit_count": 0}

	_skill_damage_stats[skill_id]["total_damage"] += info.final_damage
	_skill_damage_stats[skill_id]["hit_count"] += 1
	if info.is_crit:
		_skill_damage_stats[skill_id]["crit_count"] += 1

## 功能：记录敌人击杀统计
func _on_enemy_killed(enemy_type: String, _coord: Vector2i) -> void:
	_enemy_kills[enemy_type] = _enemy_kills.get(enemy_type, 0) + 1

## 功能：记录 BOSS 击败统计
func _on_boss_defeated(_coord: Vector2i, _layer: int) -> void:
	var boss_id: String = "boss_layer_%d" % _layer
	if not _boss_data.has(boss_id):
		_boss_data[boss_id] = {"attempts": 0, "defeats": 0}
	_boss_data[boss_id]["defeats"] += 1

## 功能：记录协同触发统计
func _on_synergy_triggered(rule_id: String, _context: Dictionary) -> void:
	_synergy_triggers[rule_id] = _synergy_triggers.get(rule_id, 0) + 1

## 功能：记录武器装备次数
func _on_weapon_equipped(weapon_id: String) -> void:
	if not _weapon_usage.has(weapon_id):
		_weapon_usage[weapon_id] = 0.0
	_weapon_usage[weapon_id] += 1.0

## 功能：记录金币收集
func _on_coin_collected(amount: int) -> void:
	_coin_data["earned"] = _coin_data.get("earned", 0) + amount

## 功能：记录商店消费
func _on_shop_item_purchased(_item_id: String, price: int) -> void:
	_coin_data["spent"] = _coin_data.get("spent", 0) + price

## 功能：记录成就解锁
func _on_achievement_unlocked(achievement_id: String) -> void:
	if not _run_data.has("achievements_unlocked"):
		_run_data["achievements_unlocked"] = []
	_run_data["achievements_unlocked"].append(achievement_id)

# ========================== 内部方法 ==========================
## 功能：将本次运行的分析数据写入 JSON 文件
func _write_analytics_file() -> void:
	# 确保目录存在
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("analytics"):
		dir.make_dir("analytics")

	# 生成文件名（时间戳）
	var timestamp: int = int(Time.get_unix_time_from_system())
	var file_path: String = ANALYTICS_DIR + "run_%d.json" % timestamp

	# 写入JSON文件
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(_run_data, "\t")
		file.store_string(json_string)
		file.close()

		if DEBUG_MODE:
			print("[AnalyticsManager] 分析数据已写入: ", file_path)
	else:
		push_warning("[AnalyticsManager] 无法写入分析文件: ", file_path)

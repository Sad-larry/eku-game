# ==============================================================================
#   player_progression_manager.gd
#   功能：玩家成长管理器（Autoload 单例），管理玩家等级和属性成长，
#        与 SaveManager 协作持久化等级状态，与 CurrencyManager 协作完成扣费。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 PlayerProgressionManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
const DEBUG_MODE: bool = true
const PROGRESSION_DATA_PATH: String = "res://resources/data/entities/player/player_progression.tres"
const DEFAULT_LEVEL: int = 1

# ========================== 信号声明模块 ==========================
signal player_level_up(new_level: int)
signal stats_updated()

# ========================== 内部变量模块 ==========================
var _player_level: int = DEFAULT_LEVEL
var _progression_data: PlayerProgression = null

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	SaveManager.data_loaded.connect(_on_save_data_loaded)
	print("PlayerProgressionManager: 玩家成长管理器初始化完成")

# ========================== 存档集成模块 ==========================
func _on_save_data_loaded() -> void:
	# 1. 加载成长配置
	_progression_data = load(PROGRESSION_DATA_PATH) as PlayerProgression

	# 2. 从 SaveManager 恢复等级
	var section: Dictionary = SaveManager.get_section("player_progression", SaveManager.DEFAULT_SECTIONS["player_progression"])
	var saved_level: int = int(section.get("player_level", DEFAULT_LEVEL))
	if _progression_data:
		_player_level = clampi(saved_level, DEFAULT_LEVEL, _progression_data.max_level)
	else:
		_player_level = saved_level

	if DEBUG_MODE:
		print("[PlayerProgressionManager] 玩家等级: Lv.", _player_level)

func _sync_to_save() -> void:
	SaveManager.set_section("player_progression", {
		"player_level": _player_level
	})
	SaveManager.save_immediately()

# ========================== 公共查询 API ==========================
func get_player_level() -> int:
	return _player_level

func get_max_level() -> int:
	if _progression_data == null:
		return DEFAULT_LEVEL
	return _progression_data.max_level

## 功能：获取下一级升级费用，已满级返回 -1
func get_level_up_cost() -> int:
	if _progression_data == null:
		return -1
	if _player_level >= _progression_data.max_level:
		return -1
	var cost_index: int = _player_level - 1  # index 0 = Lv1→Lv2
	if cost_index < _progression_data.level_up_costs.size():
		return _progression_data.level_up_costs[cost_index]
	return -1

func can_level_up() -> bool:
	var cost := get_level_up_cost()
	if cost < 0:
		return false
	return CurrencyManager.get_permanent_coin() >= cost

## 功能：获取到当前等级的累积属性加成
## 返回值：Dictionary - {"max_health": int, "damage": int, "speed": float, "crit_rate": float, "crit_damage": float}
func get_cumulative_bonuses() -> Dictionary:
	var result := {"max_health": 0, "damage": 0, "speed": 0.0, "crit_rate": 0.0, "crit_damage": 0.0}
	if _progression_data == null:
		return result
	# 累积从 Lv2 到 _player_level 的所有奖励（index 0 = Lv2）
	for i in range(_player_level - 1):
		if i < _progression_data.level_rewards.size():
			var reward: LevelUpReward = _progression_data.level_rewards[i]
			result["max_health"] += reward.max_health_bonus
			result["damage"] += reward.damage_bonus
			result["speed"] += reward.speed_bonus
			result["crit_rate"] += reward.crit_rate_bonus
			result["crit_damage"] += reward.crit_damage_bonus
	return result

## 功能：将累积加成应用到 PlayerStats 对象
## 注意：传入的 stats 应为运行时副本（通过 .duplicate()），而非共享 .tres 资源
func apply_progression_to_stats(stats: PlayerStats) -> void:
	var bonuses := get_cumulative_bonuses()
	stats.max_health += bonuses["max_health"]
	stats.damage += bonuses["damage"]
	stats.speed += bonuses["speed"]
	stats.crit_rate += bonuses["crit_rate"]
	stats.crit_damage += bonuses["crit_damage"]

# ========================== 公共操作 API ==========================
## 功能：升级玩家（扣费 + 提升等级 + 持久化）
## 返回值：bool - true 表示升级成功
func level_up() -> bool:
	if _progression_data == null:
		return false
	if _player_level >= _progression_data.max_level:
		if DEBUG_MODE:
			print("[PlayerProgressionManager] 已满级")
		return false

	var cost := get_level_up_cost()
	if cost < 0:
		return false

	if not CurrencyManager.spend_coin(cost):
		if DEBUG_MODE:
			print("[PlayerProgressionManager] 尘元不足，无法升级 (需要 ", cost, ")")
		return false

	_player_level += 1
	_sync_to_save()

	player_level_up.emit(_player_level)
	stats_updated.emit()

	if DEBUG_MODE:
		print("[PlayerProgressionManager] 升级成功 → Lv.", _player_level, " (花费 ", cost, " 尘元)")
	return true

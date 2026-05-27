# ==============================================================================
#   player_progression_panel.gd
#   功能：玩家成长面板（CanvasLayer 根节点），显示当前等级、属性、
#        下一级奖励预览和升级操作。
# ==============================================================================
extends CanvasLayer
class_name PlayerProgressionPanel

# ========================== 节点引用模块 ==========================
@onready var _level_label: Label = %LevelLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _stat_health: Label = %StatHealth
@onready var _stat_damage: Label = %StatDamage
@onready var _stat_speed: Label = %StatSpeed
@onready var _stat_crit_rate: Label = %StatCritRate
@onready var _stat_crit_damage: Label = %StatCritDamage
@onready var _reward_preview_label: Label = %RewardPreviewLabel
@onready var _cost_label: Label = %CostLabel
@onready var _level_up_btn: Button = %LevelUpButton

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_level_up_btn.pressed.connect(_on_level_up_pressed)
	CurrencyManager.coin_changed.connect(_on_coin_changed)
	if PlayerProgressionManager.ENABLED:
		PlayerProgressionManager.player_level_up.connect(_on_player_level_up)
	_refresh_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()

# ========================== 显示刷新模块 ==========================
func _refresh_display() -> void:
	if not PlayerProgressionManager.ENABLED:
		_level_label.text = "当前等级: Lv.1/1 (已禁用)"
		_progress_bar.max_value = 1
		_progress_bar.value = 1
		return

	var level: int = PlayerProgressionManager.get_player_level()
	var max_level: int = PlayerProgressionManager.get_max_level()
	_level_label.text = "当前等级: Lv.%d/%d" % [level, max_level]

	# 进度条
	if max_level > 1:
		_progress_bar.max_value = max_level - 1
		_progress_bar.value = level - 1
	else:
		_progress_bar.max_value = 1
		_progress_bar.value = 1

	# 当前属性（基础 + 成长加成）
	var bonuses: Dictionary = PlayerProgressionManager.get_cumulative_bonuses()
	var base_stats := _get_base_stats()
	_stat_health.text = "%d (+%d)" % [base_stats.max_health + bonuses["max_health"], bonuses["max_health"]]
	_stat_damage.text = "%d (+%d)" % [base_stats.damage + bonuses["damage"], bonuses["damage"]]
	_stat_speed.text = "%.0f (+%.0f)" % [base_stats.speed + bonuses["speed"], bonuses["speed"]]
	_stat_crit_rate.text = "%.1f%% (+%.1f%%)" % [
		(base_stats.crit_rate + bonuses["crit_rate"]) * 100,
		bonuses["crit_rate"] * 100
	]
	_stat_crit_damage.text = "%.0f%% (+%.0f%%)" % [
		(base_stats.crit_damage + bonuses["crit_damage"]) * 100,
		bonuses["crit_damage"] * 100
	]

	# 升级区域
	if level >= max_level:
		_reward_preview_label.text = ""
		_cost_label.text = ""
		_level_up_btn.text = "已满级"
		_level_up_btn.disabled = true
		return

	# 下一级奖励预览
	if not PlayerProgressionManager.ENABLED:
		_reward_preview_label.text = ""
		_cost_label.text = ""
		_level_up_btn.text = "升级"
		_level_up_btn.disabled = true
		return

	var progression: PlayerProgression = load(PlayerProgressionManager.PROGRESSION_DATA_PATH)
	if progression and (level - 1) < progression.level_rewards.size():
		var reward: LevelUpReward = progression.level_rewards[level - 1]
		var parts: Array[String] = []
		if reward.max_health_bonus > 0:
			parts.append("+%d 生命" % reward.max_health_bonus)
		if reward.damage_bonus > 0:
			parts.append("+%d 攻击" % reward.damage_bonus)
		if reward.speed_bonus > 0:
			parts.append("+%.0f 移速" % reward.speed_bonus)
		if reward.crit_rate_bonus > 0:
			parts.append("+%.1f%% 暴击" % (reward.crit_rate_bonus * 100))
		if reward.crit_damage_bonus > 0:
			parts.append("+%.0f%% 暴伤" % (reward.crit_damage_bonus * 100))
		_reward_preview_label.text = "下一级: " + ", ".join(parts) if not parts.is_empty() else ""
	else:
		_reward_preview_label.text = ""

	# 费用和按钮
	var cost: int = PlayerProgressionManager.get_level_up_cost()
	_cost_label.text = "费用: %d 尘元" % cost if cost >= 0 else ""
	var can_upgrade := PlayerProgressionManager.can_level_up()
	_level_up_btn.text = "升级"
	_level_up_btn.disabled = not can_upgrade

func _get_base_stats() -> Dictionary:
	var stats: PlayerStats = load("res://resources/data/entities/player/stats_player.tres")
	if stats:
		return {
			"max_health": stats.max_health,
			"damage": stats.damage,
			"speed": stats.speed,
			"crit_rate": stats.crit_rate,
			"crit_damage": stats.crit_damage,
		}
	return {"max_health": 0, "damage": 0, "speed": 0.0, "crit_rate": 0.0, "crit_damage": 0.0}

# ========================== 操作模块 ==========================
func _on_level_up_pressed() -> void:
	if not PlayerProgressionManager.ENABLED:
		return
	var success := PlayerProgressionManager.level_up()
	if success:
		_refresh_display()

func _on_player_level_up(_new_level: int) -> void:
	_refresh_display()

func _on_coin_changed(_current: int, _permanent: int) -> void:
	_refresh_display()

# ========================== 关闭模块 ==========================
func _on_close_button_pressed() -> void:
	queue_free()

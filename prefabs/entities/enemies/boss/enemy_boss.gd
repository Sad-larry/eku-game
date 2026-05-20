# ==============================================================================
#   enemy_boss.gd
#   功能：Boss 类型敌人，继承自 Enemy，支持多阶段战斗。
#        通过 BossConfig 配置阶段数、血量阈值和奖励。
#        行为（技能）通过 Enemy.behaviors 数组 + PhaseTrigger 统一管理。
# ==============================================================================
extends Enemy
class_name EnemyBoss

# ========================== 信号声明模块 ==========================
## 阶段切换时发射（参数：新阶段索引，从 0 开始）
signal phase_changed(new_phase: int)
## Boss 被击败时发射
signal boss_defeated()

# ========================== 导出变量模块 ==========================
## Boss 配置资源（阶段数、血量阈值、奖励等）
@export var boss_config: BossConfig
## Boss阶段数据列表（每个阶段的属性配置）
@export var phases_data: Array[BossPhaseData] = []
## Boss技能掉落配置
@export var skill_drop_config: BossSkillDrop

# ========================== 运行时状态变量 ==========================
## 当前阶段索引（从 0 开始）
var _current_phase: int = 0
## Boss 所在房间坐标（由 GameWorld 在生成时设置）
var boss_room_coord: Vector2i = Vector2i.ZERO
## 当前阶段数据
var _current_phase_data: BossPhaseData

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	super._ready()
	# 禁用 Boss 的普通死亡流程，使用自定义流程
	health_component.unit_died.disconnect(_on_died)
	health_component.unit_died.connect(_on_boss_died)

	# 初始化阶段数据
	_initialize_phases()

# ========================== 公共 API 模块 ==========================
## 功能：设置 Boss 配置（由 GameWorld 在生成后调用）
func setup_boss(config: BossConfig, coord: Vector2i) -> void:
	boss_config = config
	boss_room_coord = coord
	_current_phase = 0
	_initialize_phases()

## 功能：获取当前阶段索引
func get_current_phase() -> int:
	return _current_phase

## 功能：获取总阶段数
func get_total_phases() -> int:
	if boss_config:
		return boss_config.phases
	return 1

# ========================== 阶段系统模块 ==========================
## 功能：重写受击逻辑，添加阶段转换判断
func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	super._on_hurtbox_component_damaged(hitbox)
	_check_phase_transition()

## 功能：检查血量是否跨过阶段阈值
func _check_phase_transition() -> void:
	if boss_config == null:
		return
	var health_pct: float = health_component.get_health_percentage()
	var next_phase: int = _current_phase + 1
	while next_phase <= boss_config.phase_health_thresholds.size():
		var threshold_index: int = next_phase - 1
		if threshold_index < boss_config.phase_health_thresholds.size():
			var threshold: float = boss_config.phase_health_thresholds[threshold_index]
			if health_pct <= threshold:
				_current_phase = next_phase
				_on_phase_transition(_current_phase)
				phase_changed.emit(_current_phase)
			else:
				break
		next_phase += 1

## 功能：阶段切换时的处理
func _on_phase_transition(new_phase: int) -> void:
	if Global.DEBUG_MODE:
		print("[Boss] 阶段切换: %d → %d" % [new_phase - 1, new_phase])
	_apply_phase_data(new_phase)

# ========================== 死亡处理模块 ==========================
## 功能：Boss 死亡回调
func _on_boss_died() -> void:
	# 清理行为组件
	for behavior in behaviors:
		behavior.cleanup()

	boss_defeated.emit()
	EventBus.boss_defeated.emit(boss_room_coord, RunManager.current_layer)

	# 发放奖励金币
	if boss_config:
		for i in boss_config.reward_coins:
			var coin: CoinPickup = COIN_PICKUP_SCENE.instantiate()
			get_parent().add_child(coin)
			coin.global_position = global_position
			var angle: float = randf_range(0, TAU)
			coin.spawn(COIN_DATA, Vector2.from_angle(angle), randf_range(100.0, 250.0))

	# 处理BOSS技能掉落
	_process_skill_drop()

	# Boss 击败后弹出遗物选择
	EventBus.relic_selection_requested.emit()

	# 切换到死亡状态
	enemy_state_machine.change_to("dead")

## 功能：处理BOSS技能掉落
func _process_skill_drop() -> void:
	if skill_drop_config == null:
		return

	var boss_id := skill_drop_config.boss_id
	if boss_id.is_empty():
		boss_id = boss_config.boss_name if boss_config else "unknown"

	var is_first_clear := _check_first_clear(boss_id)

	var should_drop := false
	if is_first_clear and skill_drop_config.first_clear_guaranteed:
		should_drop = true
	elif randf() <= skill_drop_config.repeat_drop_chance:
		should_drop = true

	if not should_drop:
		return

	var dropped_skills := _select_drop_skills()
	if dropped_skills.is_empty():
		return

	for skill in dropped_skills:
		if skill_drop_config.direct_unlock:
			SkillUnlockManager.unlock_skill_by_id(skill.id)
		EventBus.boss_skill_dropped.emit(boss_id, skill.id)

	_show_reward_ui(dropped_skills)

	if is_first_clear:
		_record_first_clear(boss_id)

## 功能：检查是否首次击败
func _check_first_clear(boss_id: String) -> bool:
	var boss_defeats: Dictionary = SaveManager.get_section("boss_defeats", {})
	var first_clear_claimed: Array = boss_defeats.get("first_clear_claimed", [])
	return boss_id not in first_clear_claimed

## 功能：记录首次击败
func _record_first_clear(boss_id: String) -> void:
	var boss_defeats: Dictionary = SaveManager.get_section("boss_defeats", {})
	var first_clear_claimed: Array = boss_defeats.get("first_clear_claimed", [])
	first_clear_claimed.append(boss_id)
	boss_defeats["first_clear_claimed"] = first_clear_claimed
	SaveManager.set_section("boss_defeats", boss_defeats)
	SaveManager.save_immediately()

## 功能：选择掉落的技能
func _select_drop_skills() -> Array[SkillEffect]:
	var result: Array[SkillEffect] = []
	if skill_drop_config.drop_skills.is_empty():
		return result
	var available_skills := skill_drop_config.drop_skills.duplicate()
	for i in skill_drop_config.drop_count:
		if available_skills.is_empty():
			break
		var index := randi() % available_skills.size()
		result.append(available_skills[index])
		available_skills.remove_at(index)
	return result

## 功能：显示奖励UI
func _show_reward_ui(skills: Array[SkillEffect]) -> void:
	var reward_scene: PackedScene = preload("res://scenes/ui/boss_skill_reward/boss_skill_reward.tscn")
	var reward_ui: Control = reward_scene.instantiate()
	get_tree().current_scene.add_child(reward_ui)
	if skills.size() > 0:
		reward_ui.show_reward(skills[0])
		reward_ui.reward_claimed.connect(func():
			if skills.size() > 1:
				skills.remove_at(0)
				reward_ui.show_reward(skills[0])
			else:
				reward_ui.queue_free()
		)

# ========================== 阶段数据应用 ==========================
## 功能：初始化阶段数据
func _initialize_phases() -> void:
	if phases_data.is_empty():
		if Global.DEBUG_MODE:
			print("[Boss] 未配置阶段数据，使用默认行为")
		return
	_apply_phase_data(0)

## 功能：应用阶段属性倍率
func _apply_phase_data(phase_index: int) -> void:
	if phase_index < 0 or phase_index >= phases_data.size():
		return

	_current_phase_data = phases_data[phase_index]
	_apply_phase_multipliers()

	if Global.DEBUG_MODE:
		print("[Boss] 应用阶段 ", phase_index, " 数据")

## 功能：应用阶段属性倍率
func _apply_phase_multipliers() -> void:
	if _current_phase_data == null:
		return

	# 应用无敌状态
	if _current_phase_data.is_invincible:
		_start_invincible(_current_phase_data.invincible_duration)

## 功能：开始无敌状态
func _start_invincible(duration: float) -> void:
	set("is_invincible", true)
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_end_invincible)
	timer.start()
	_apply_invincible_visual()

## 功能：结束无敌状态
func _end_invincible() -> void:
	set("is_invincible", false)
	_remove_invincible_visual()
	if Global.DEBUG_MODE:
		print("[Boss] 无敌状态结束")

## 功能：应用无敌视觉效果
func _apply_invincible_visual() -> void:
	modulate = Color(1, 1, 1, 0.5)

## 功能：移除无敌视觉效果
func _remove_invincible_visual() -> void:
	modulate = Color(1, 1, 1, 1)

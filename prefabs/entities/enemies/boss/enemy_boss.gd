# ==============================================================================
#   enemy_boss.gd
#   功能：Boss 类型敌人，继承自 Enemy，支持多阶段战斗。
#        通过 BossConfig 配置阶段数、血量阈值和奖励。
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

# ========================== 运行时状态变量 ==========================
## 当前阶段索引（从 0 开始）
var _current_phase: int = 0
## Boss 所在房间坐标（由 GameWorld 在生成时设置）
var boss_room_coord: Vector2i = Vector2i.ZERO

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	super._ready()
	# 禁用 Boss 的普通死亡流程，使用自定义流程
	health_component.unit_died.disconnect(_on_died)
	health_component.unit_died.connect(_on_boss_died)

# ========================== 公共 API 模块 ==========================
## 功能：设置 Boss 配置（由 GameWorld 在生成后调用）
func setup_boss(config: BossConfig, coord: Vector2i) -> void:
	boss_config = config
	boss_room_coord = coord
	_current_phase = 0

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
	# 检查是否满足下一阶段的血量阈值
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

## 功能：阶段切换时的处理（子类可重写扩展攻击模式）
func _on_phase_transition(new_phase: int) -> void:
	if Global.DEBUG_MODE:
		print("[Boss] 阶段切换: %d → %d" % [new_phase - 1, new_phase])
	# 阶段切换时短暂无敌（视觉反馈）
	# 子类可重写此方法添加攻击模式切换、特效等

# ========================== 死亡处理模块 ==========================
## 功能：Boss 死亡回调（替换默认 Enemy 的 _on_died）
func _on_boss_died() -> void:
	# 发射 Boss 击败信号
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

	# Boss 击败后弹出遗物选择
	EventBus.relic_selection_requested.emit()

	# 切换到死亡状态
	enemy_state_machine.change_to("dead")

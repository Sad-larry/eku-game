# ==============================================================================
#   idle_state.gd
#   功能：敌人待机状态，播放待机动画，持续检测玩家距离，进入索敌范围时切换为追击状态。
# ==============================================================================
extends EnemyState
class_name EnemyIdleState

# ========================== 常量定义模块 ==========================
## 到达游走目标点的判定阈值（像素）
const ARRIVAL_THRESHOLD: float = 8.0

# ========================== 内部变量模块 ==========================
## 游走计时器（秒），递减到0时切换行为
var _behavior_timer: float = 0.0
## 当前是否正在游走移动（false 表示站立发呆）
var _is_wandering: bool = false
## 当前游走目标位置
var _wander_target: Vector2 = Vector2.ZERO

# ========================== 状态生命周期模块 ==========================
func enter() -> void:
	get_anim().play_state("idle")
	_pick_new_behavior()

## 功能：每帧更新，检测玩家进入 + 管理游走行为切换
func update(delta: float) -> void:
	# 检测玩家是否被 VisionArea 发现
	if _enemy.player_detected:
		get_movement().stop_immediately()
		state_machine.change_to("move")
		return
	
	# 游走/发呆计时
	_behavior_timer -= delta
	if _behavior_timer <= 0.0:
		_pick_new_behavior()

## 功能：每物理帧更新，处理游走移动
func physics_update(delta: float) -> void:
	if not _is_wandering:
		return
	
	# 计算朝向游走目标的方向
	var target_pos: Vector2 = _wander_target
	var direction: Vector2 = (target_pos - _enemy.global_position).normalized()
	var dist: float = _enemy.global_position.distance_to(target_pos)
	
	if dist > ARRIVAL_THRESHOLD:
		get_movement().move_toward(direction, delta)
		_enemy.move_and_slide()
	else:
		# 到达目标点，切换行为
		get_movement().stop_immediately()
		_pick_new_behavior()

# ========================== 内部方法模块 ==========================
## 功能：随机选择下一个行为（发呆或游走）
func _pick_new_behavior() -> void:
	var roll: float = randf()
	
	if roll < 0.4:
		# 40% 概率：站立发呆
		_is_wandering = false
		_behavior_timer = randf_range(
			_enemy.stats_resource.wander_pause_range.x,
			_enemy.stats_resource.wander_pause_range.y
		)
		get_anim().play_state("idle")
	else:
		# 60% 概率：随机游走
		_is_wandering = true
		_behavior_timer = randf_range(
			_enemy.stats_resource.wander_move_range.x,
			_enemy.stats_resource.wander_move_range.y
		)
		_pick_wander_target()
		get_anim().play_state("move")

## 功能：在游走范围内随机选取一个目标点
func _pick_wander_target() -> void:
	var spawn: Vector2 = _enemy.spawn_position
	var range_val: float = _enemy.stats_resource.wander_range
	var offset: Vector2 = Vector2(
		randf_range(-range_val, range_val),
		randf_range(-range_val, range_val)
	)
	_wander_target = spawn + offset

# ========================== 事件处理模块 ==========================
## 功能：待机状态中接收到事件时的回调
## 参数：event_name (String) - 事件名称（如 "move"、"attack"、"hurt"、"dead"、"skill"）
func on_event(event_name: String) -> void:
	match event_name:
		"move":
			state_machine.change_to("move")
		"attack":
			state_machine.change_to("attack")
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")
		"skill":
			state_machine.change_to("skill")

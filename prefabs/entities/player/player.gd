# ==============================================================================
#   player.gd
#   功能：玩家核心控制器，处理移动输入、动画状态机、生命值/能量管理、技能系统、
#        战斗判定连接等。继承自 CharacterBody2D，作为玩家实体的主体脚本。
# ==============================================================================
extends CharacterBody2D
class_name Player
# ========================== 导出变量模块 ==========================
## 玩家属性配置资源（包含生命值、能量值等基础属性）
@export var stats_resource: Resource

# ========================== 节点引用模块 ==========================
## 动画树节点（用于驱动混合动画）
@onready var anim_tree: AnimationTree = $AnimationTree
## 动画状态机播放控制器（用于控制移动状态机）
@onready var move_state_machine: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/MoveStateMachine/playback")
## 攻击组件（管理连击窗口、判定帧等）
@onready var attack_component: AttackComponent = %AttackComponent
## 生命值组件（位于 StatsComponents 子节点下）
@onready var health_component: HealthComponent = $StatsComponents/HealthComponent
## 能量值组件（位于 StatsComponents 子节点下）
@onready var energy_component: EnergyComponent = $StatsComponents/EnergyComponent
## 攻击判定框组件（用于主动攻击命中敌人）
@onready var hitbox_component: HitboxComponent = $StatsComponents/HitboxComponent
## 玩家动画控制器（处理移动方向与动画的参数传递）
@onready var anim_controller: PlayerAnimationController = $PlayerAnimationController
## 玩家移动组件（处理速度、加速度、移动逻辑）
@onready var movement_component: PlayerMovementComponent = $PlayerMovementComponent
## 玩家状态机（管理玩家等状态）
@onready var player_state_machine: PlayerStateMachine = $PlayerStateMachine
## 目标检测区域（用于技能/攻击时寻找最近的敌人）
@onready var target_detector: Area2D = %TargetDetector

# ========================== 变量定义模块 ==========================
## 最后一次移动方向（用于动画朝向、攻击朝向等）
var last_direction: Vector2 = Vector2.DOWN

## 输入是否被禁用（用于对话框等场景，阻断信号驱动的输入）
var input_disabled: bool = false

## 面朝方向（由 WASD 最后按下方向决定，无输入时保持最后朝向）
var _facing_direction: Vector2 = Vector2.DOWN

## 击退速度向量（受击时的临时位移）
var velocity_knockback: Vector2 = Vector2.ZERO

## 是否处于攻击状态（用于逻辑判断，如移动限制）
var is_attacking: bool = false

## 技能运行器字典（key: 技能 ID, value: SkillRunner 实例）
var _skill_runners: Dictionary = {}

## 技能槽数据数组（预加载的四个技能资源配置）
var _skill_slot_data: Array[SkillEffect] = [
	preload("res://resources/data/skills/initiator/fireball_01.tres"),
	preload("res://resources/data/skills/control/vortex_01.tres"),
	preload("res://resources/data/skills/finisher/pierce_01.tres"),
	preload("res://resources/data/skills/finisher/pierce_02.tres"),
]

## 输入动作名到技能槽索引的映射表
const SKILL_SLOT_MAP: Dictionary = {
	"skill_1": 0,
	"skill_2": 1,
	"skill_3": 2,
	"skill_4": 3,
}

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化玩家属性、组件、状态机、信号连接
func _ready():
	# 将玩家添加到 "player" 组，并注册到全局单例
	add_to_group("player")
	Global.player = self
	
	# 连接生命值组件信号
	health_component.health_updated.connect(_on_health_forward_to_bus)
	health_component.unit_died.connect(_on_unit_died)
	energy_component.energy_changed.connect( _on_energy_forward_to_bus)
	
	# 初始化生命值组件（必须在使用 health_component.current_health 之前调用）
	health_component.setup(stats_resource)
	energy_component.setup(stats_resource)
	
	movement_component.setup(stats_resource)
	
	# 连接输入管理器信号
	InputManager.action_triggered.connect(_on_input_action)
	InputManager.movement_vector_changed.connect(_on_movement_changed)
	
	# 初始化状态机
	player_state_machine.init_states(self)
	# 初始化技能槽
	_init_skill_runner()
	
	# 连接全局事件总线信号
	EventBus.skill_slot_clicked.connect(_on_skill_slot_clicked)
	EventBus.skill_damage_requested.connect(_on_skill_damage_requested)
	EventBus.player_died.connect(_on_player_died)
	
	 # 通知全局系统玩家已就绪
	EventBus.player_ready.emit()
	print("Player: 初始化完成")

## 功能：节点退出场景树时清理全局引用，避免悬挂指针
func _exit_tree() -> void:
	if Global.player == self:
		Global.player = null

## 功能：每物理帧更新玩家移动与状态
## 参数：delta (float) - 物理帧间隔时间（秒）
func _physics_process(delta: float):
	# 仅在允许移动的状态下（idle / move）更新移动输入
	if player_state_machine.is_movement_allowed():
		var input_dir = InputManager.get_movement_vector()
		movement_component.update_movement(input_dir, delta)
		var move_dir = movement_component.get_movement_direction()
		if move_dir != Vector2.ZERO:
			last_direction = move_dir
	
	# 将玩家朝向传递给动画控制器
	anim_controller.set_movement_direction(last_direction)
	
	# 应用速度并移动
	move_and_slide()

# ========================== 输入处理模块 ==========================
## 功能：输入动作触发时的回调（由 InputManager.action_triggered 信号触发）
## 参数：action (String) - 输入动作名称（如 "attack"、"skill_1" 等）
## TODO: 这里将所有的输入事件都派发给状态机，可是还有其他输入事件如 ui_confirm_q、ui_cancel_e 等状态机是处理不了的
##       后续可根据输入动作分类，仅将战斗/移动相关动作转发给状态机
func _on_input_action(action: String):
	if input_disabled:
		return
	# 将所有输入事件派发给状态机，由当前状态决定是否响应
	player_state_machine.send_event(action)

## 功能：移动向量变化时的回调（由 InputManager.movement_vector_changed 信号触发）
## 参数：dir (Vector2) - 当前移动方向（单位向量）
func _on_movement_changed(dir: Vector2) -> void:
	if input_disabled:
		return
	if dir != Vector2.ZERO:
		_facing_direction = dir.normalized()
		player_state_machine.send_event("move")
	else:
		player_state_machine.send_event("idle")

# ========================== 状态机初始化模块 ==========================
## 连接所有 SkillRunner 的冷却信号，转发到 EventBus（供 UI 更新）
func _init_skill_runner() -> void:
	# 创建持久化 SkillRunner 池
	for slot_index in _skill_slot_data.size():
		var slot_data := _skill_slot_data[slot_index]
		# 创建并挂载技能执行器
		var runner := SkillRunner.new(slot_data, self)
		add_child(runner)
		_skill_runners[slot_data.id] = runner
		runner.cooldown_updated.connect(_on_runner_cooldown_updated.bind(slot_index))
		runner.cooldown_finished.connect(_on_runner_cooldown_finished.bind(slot_index))
	

# ========================== 公共 API 模块 ==========================
## 功能：根据技能 ID 获取对应的技能运行器
## 参数：skill_id (String) - 技能唯一标识
## 返回值：SkillRunner - 技能运行器实例，若未找到则返回 null
func get_skill_runner(skill_id: String) -> SkillRunner:
	return _skill_runners.get(skill_id)

## 功能：根据输入动作名称获取对应技能槽的技能数据
## 参数：action_name (String) - 输入动作名称（如 "skill_1"）
## 返回值：SkillEffect - 技能资源，若未找到则返回 null
func get_skill_data_by_action(action_name: String) -> SkillEffect:
	var idx = SKILL_SLOT_MAP.get(action_name, -1)
	if idx < 0 or idx >= _skill_slot_data.size():
		return null
	return _skill_slot_data[idx]

## 功能：获取当前攻击/技能的目标（最近的敌人）
## 返回值：Node - 目标敌人节点，若无有效目标则返回 null
## TODO: 实现完整的目标检测逻辑：
##       1. 检测前方扇形/圆形范围内最近的敌人
##       2. 使用射线检测或 Area2D 重叠区域 + 方向过滤
##       3. 示例代码已预留，需根据实际物理射线查询完善
func get_target() -> Node:
	# 实现思路：检测前方扇形/圆形范围内最近的敌人
	var candidates: Array[Area2D] = target_detector.get_overlapping_areas()
	var nearest: Enemy = null
	var nearest_dist: float = INF

	for area in candidates:
		var enemy: Enemy = area.owner as Enemy
		if enemy == null:
			continue
		# 过滤面朝方向外的敌人（点积 > 0.5，即 ±45° 锥形范围）
		var to_enemy: Vector2 = (enemy.global_position - global_position).normalized()
		if to_enemy.dot(_facing_direction) < 0.5:
			continue
		var d: float = global_position.distance_squared_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy

	return nearest

## 功能：玩家停止移动
func disable_movement() -> void:
	movement_component.stop_immediately()
	set_physics_process(false)
	input_disabled = true

## 功能：玩家恢复移动
func enable_movement() -> void:
	set_physics_process(true)
	input_disabled = false
# ========================== 信号回调模块 ==========================
## 功能：受击框组件受到伤害时的回调（需手动连接 HurtboxComponent 的 damaged 信号）
## 参数：hitbox (HitboxComponent) - 攻击来源的判定框组件
func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	# 已死亡则不再处理伤害
	if health_component.current_health <= 0:
		return
	health_component.take_damage(hitbox.damage)
	player_state_machine.send_event("hurt")

## 功能：将生命值变化转发到全局事件总线（供 HUD 等界面监听）
## 参数：new_health (int) - 当前生命值；max_health (int) - 最大生命值
func _on_health_forward_to_bus(new_health: int, max_health: int) -> void:
	EventBus.health_updated.emit(new_health, max_health)

## 功能：将能量值变化转发到全局事件总线（供 HUD 等界面监听）
## 参数：new_energy (int) - 当前能量值；max_energy (int) - 最大能量值
func _on_energy_forward_to_bus(new_energy: int, max_energy: int) -> void:
	EventBus.energy_updated.emit(new_energy, max_energy)

## 功能：单位死亡时的回调（触发玩家死亡状态）
func _on_unit_died() -> void:
	player_state_machine.send_event("dead")

## 功能：玩家死亡全局事件回调（由 EventsBus.player_died 触发）
func _on_player_died() -> void:
	UIManager.open_game_over()

## 功能：技能伤害请求回调（由 EventsBus.skill_damage_requested 触发）
## 参数：damage_data (Dictionary) - 伤害数据字典（需包含 target 和 damage 字段）
## TODO: 建议将 damage_data 类型从 Dictionary 替换为强类型资源 DamageData
func _on_skill_damage_requested(damage_data: Dictionary) -> void:
	var target = damage_data.get("target")
	var damage = damage_data.get("damage", 0)
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

## 功能：鼠标点击技能槽时触发（映射为对应输入动作，复用键盘输入路径）
## 参数：slot_index (int) - 技能槽索引（0~3）
func _on_skill_slot_clicked(slot_index: int) -> void:
	var action_names := ["skill_1", "skill_2", "skill_3", "skill_4"]
	if slot_index >= 0 and slot_index < action_names.size():
		_on_input_action(action_names[slot_index])

## 功能：SkillRunner 冷却进度更新时转发到 EventBus（供 HUD 显示）
## 参数：remaining (float) - 剩余冷却秒数；total (float) - 总冷却秒数；slot_index (int) - 技能槽索引
func _on_runner_cooldown_updated(remaining: float, total: float, slot_index: int) -> void:
	EventBus.skill_cooldown_updated.emit(slot_index, remaining, total)

## 功能：SkillRunner 冷却结束时转发到 EventBus（供 HUD 隐藏遮罩）
## 参数：slot_index (int) - 技能槽索引
func _on_runner_cooldown_finished(slot_index: int) -> void:
	EventBus.skill_cooldown_finished.emit(slot_index)

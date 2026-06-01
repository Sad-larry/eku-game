# ==============================================================================
#   player.gd
#   功能：玩家核心控制器，作为各子系统的协调入口。
#        职责缩减为：节点引用、初始化编排、对外公开 API、极简物理帧。
# ==============================================================================
extends CharacterBody2D
class_name Player

# ========================== 导出变量模块 ==========================
## 玩家属性配置资源（包含生命值、能量值等基础属性）
@export var stats_resource: Resource

# ========================== 节点引用模块 ==========================
@onready var health_component: HealthComponent = $Stats/HealthComponent
@onready var energy_component: EnergyComponent = $Stats/EnergyComponent
@onready var hitbox_component: HitboxComponent = $Combat/HitboxComponent
@onready var anim_controller: PlayerAnimationController = $AnimationController
@onready var movement_component: PlayerMovementComponent = $MovementComponent
@onready var player_state_machine: PlayerStateMachine = $StateMachine
@onready var skill_manager: PlayerSkillManager = $SkillManager
@onready var input_handler: PlayerInputHandler = $InputHandler

# ========================== 变量定义模块 ==========================
## 状态效果组件（管理增益、减益、DOT 等效果）
var status_effect_component: StatusEffectComponent
## 最后有效移动方向（只读，委托至 MovementComponent）
var last_direction: Vector2:
	get:
		return movement_component.last_direction

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化玩家属性、信号连接、子系统编排
func _ready() -> void:
	add_to_group("player")
	Global.player = self

	# 创建占位图视觉（开发阶段）
	#_setup_placeholder_visual()

	health_component.health_updated.connect(_on_health_forward_to_bus)
	health_component.unit_died.connect(_on_unit_died)
	energy_component.energy_changed.connect(_on_energy_forward_to_bus)

	# 创建 stats 运行时副本，避免修改共享 .tres 资源
	stats_resource = stats_resource.duplicate()
	if PlayerProgressionManager.ENABLED:
		PlayerProgressionManager.apply_progression_to_stats(stats_resource)

	health_component.setup(stats_resource)
	energy_component.setup(stats_resource)
	movement_component.setup(stats_resource)

	# 初始化状态效果组件
	status_effect_component = StatusEffectComponent.new()
	status_effect_component.name = "StatusEffectComponent"
	add_child(status_effect_component)
	status_effect_component.setup(self)

	input_handler.input_action.connect(_on_input_action)
	input_handler.movement_dir_changed.connect(_on_movement_changed)

	EventBus.player_died.connect(_on_player_died)
	if PlayerProgressionManager.ENABLED:
		PlayerProgressionManager.stats_updated.connect(_on_progression_stats_updated)

	EventBus.player_ready.emit()
	print("Player: 初始化完成")

## 功能：节点退出场景树时清理全局引用，避免悬挂指针
func _exit_tree() -> void:
	if Global.player == self:
		Global.player = null

## 功能：每物理帧更新玩家移动与动画方向
## 参数：delta (float) - 物理帧间隔时间（秒）
func _physics_process(delta: float) -> void:
	var speed_mult := _get_current_speed_multiplier() if player_state_machine.is_movement_allowed() else 0.0
	movement_component.update_movement(delta, speed_mult)

	anim_controller.set_movement_direction(movement_component.last_direction)
	anim_controller.update_arm_sorting(movement_component.last_direction)
	move_and_slide()


# ========================== 输入处理模块 ==========================
## 功能：输入动作触发时的回调。
##       技能动作委托 skill_manager.try_execute() 处理前置条件，
##       通过后通知状态机播放动画。非技能动作直接转发。
##       攻击动作会检查 MouseSwipeDetector.is_dragging，防止拖拽时误触攻击。
## 参数：action (String) - 输入动作名称（如 "attack"、"skill_1"）
func _on_input_action(action: String) -> void:
	# 安全检查：鼠标拖拽期间忽略攻击动作（滑动检测器已消费事件，此为双重保险）
	if action == "attack" and MouseSwipeDetector.is_dragging:
		return

	if action.begins_with("skill_"):
		if skill_manager.try_execute(action):
			player_state_machine.send_event(action)
		return

	player_state_machine.send_event(action)

## 功能：移动方向变化时的回调，通知状态机切换移动/待机状态
## 参数：dir (Vector2) - 当前移动方向（单位向量）
func _on_movement_changed(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		player_state_machine.send_event("move")
	else:
		player_state_machine.send_event("idle")

# ========================== 公共 API 模块 ==========================
## 功能：停止玩家移动并禁用输入
## 说明：用于对话框、过场动画等需要暂时剥夺玩家控制权的场景
func disable_movement() -> void:
	movement_component.stop_immediately()
	set_physics_process(false)
	EventBus.input_blocking_updated.emit(["skill_", "attack", "move_", "interact"])

## 功能：恢复玩家移动与输入
func enable_movement() -> void:
	set_physics_process(true)
	EventBus.input_blocking_updated.emit([])

# ========================== 信号回调模块 ==========================
## 功能：受击框受到伤害时的回调，执行扣血并通知状态机进入受击状态
## 参数：hitbox (HitboxComponent) - 攻击来源的判定框组件
## 说明：若玩家已死亡则不再处理伤害
func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	if health_component.current_health <= 0:
		return
	health_component.take_damage(hitbox.damage)
	# 记录玩家受到的伤害统计
	if RunManager.is_run_active():
		RunManager.record_damage_taken(hitbox.damage)
	player_state_machine.send_event("hurt")

## 功能：将生命值变化转发到全局事件总线（供 HUD 界面监听）
## 参数：new_health (int) - 当前生命值；max_health (int) - 最大生命值
func _on_health_forward_to_bus(new_health: int, max_health: int) -> void:
	EventBus.health_updated.emit(new_health, max_health)

## 功能：将能量值变化转发到全局事件总线（供 HUD 界面监听）
## 参数：new_energy (int) - 当前能量值；max_energy (int) - 最大能量值
func _on_energy_forward_to_bus(new_energy: int, max_energy: int) -> void:
	EventBus.energy_updated.emit(new_energy, max_energy)

## 功能：单位死亡时的回调，通知状态机切换到死亡状态
## 说明：实际死亡动画播放和后续 UI 面板由死亡状态内部处理
func _on_unit_died() -> void:
	player_state_machine.send_event("dead")

## 功能：死亡动画播放完毕后的回调，结束运行并打开游戏结束面板
func _on_player_died() -> void:
	# 结束当前运行
	if RunManager.is_run_active():
		RunManager.end_run(RunManager.RunStatus.FAILED, "enemy")
	# 打开游戏结束界面
	UIManager.open_ui("game_over")

## 功能：玩家成长属性更新时重新应用加成并刷新组件
func _on_progression_stats_updated() -> void:
	if not PlayerProgressionManager.ENABLED:
		return
	# 重新从基础 .tres 创建副本并叠加新的成长加成
	var base_stats: Resource = load("res://resources/data/entities/player/stats_player.tres")
	stats_resource = base_stats.duplicate()
	PlayerProgressionManager.apply_progression_to_stats(stats_resource)
	health_component.setup(stats_resource)
	energy_component.setup(stats_resource)
	movement_component.setup(stats_resource)

# ========================== 辅助方法模块 ==========================
## 功能：获取当前状态的移速倍率。
## 说明：技能释放期间若允许移动，技能数据可能附带移速倍率。同时叠加状态效果修正。
func _get_current_speed_multiplier() -> float:
	var state_mult := 1.0
	var state := player_state_machine.get_current_state()
	if state and state.has_method("get_move_speed_multiplier"):
		state_mult = state.get_move_speed_multiplier()
	var effect_mult := 1.0
	if status_effect_component:
		effect_mult = status_effect_component.get_speed_multiplier()
	return state_mult * effect_mult

## 功能：设置占位图视觉（开发阶段使用）
## 说明：隐藏原有的动画和精灵，添加占位图组件
func _setup_placeholder_visual() -> void:
	# 隐藏原有的 Visual 节点
	var visual_node := get_node_or_null("Visual")
	if visual_node:
		visual_node.visible = false

	# 隐藏原有的 Sprite2D 节点
	var sprite_node := get_node_or_null("Sprite2D")
	if sprite_node:
		sprite_node.visible = false

	# 创建占位图组件
	var placeholder := PlaceholderSprite.new()
	placeholder.name = "PlaceholderSprite"
	placeholder.placeholder_type = "player"
	placeholder.placeholder_size = Vector2(24, 40)  # 玩家占位图尺寸
	add_child(placeholder)

	# 将占位图移到最前面
	move_child(placeholder, 0)

	print("Player: 已创建占位图视觉")

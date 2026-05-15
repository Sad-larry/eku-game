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
## 最后一次移动方向（用于动画朝向、攻击朝向等）
var last_direction: Vector2 = Vector2.DOWN
## 面朝方向
var _facing_direction: Vector2 = Vector2.DOWN
## 输入是否被禁用（用于对话框等场景）
var input_disabled: bool = false

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化玩家属性、信号连接、子系统编排
func _ready() -> void:
	add_to_group("player")
	Global.player = self

	health_component.health_updated.connect(_on_health_forward_to_bus)
	health_component.unit_died.connect(_on_unit_died)
	energy_component.energy_changed.connect(_on_energy_forward_to_bus)

	health_component.setup(stats_resource)
	energy_component.setup(stats_resource)
	movement_component.setup(stats_resource)

	input_handler.input_action.connect(_on_input_action)
	input_handler.movement_dir_changed.connect(_on_movement_changed)

	EventBus.skill_slot_clicked.connect(_on_skill_slot_clicked)
	EventBus.player_died.connect(_on_player_died)

	EventBus.player_ready.emit()
	print("Player: 初始化完成")

## 功能：节点退出场景树时清理全局引用，避免悬挂指针
func _exit_tree() -> void:
	if Global.player == self:
		Global.player = null

## 功能：每物理帧更新玩家移动与动画方向
## 参数：delta (float) - 物理帧间隔时间（秒）
func _physics_process(delta: float) -> void:
	if player_state_machine.is_movement_allowed():
		var input_dir := InputManager.get_movement_vector()
		movement_component.update_movement(input_dir, delta)
		var move_dir := movement_component.get_movement_direction()
		if move_dir != Vector2.ZERO:
			last_direction = move_dir

	anim_controller.set_movement_direction(last_direction)
	anim_controller.update_arm_sorting(last_direction)
	move_and_slide()

# ========================== 输入处理模块 ==========================
## 功能：输入动作触发时的回调，转发给状态机由当前状态决定是否响应
## 参数：action (String) - 输入动作名称（如 "attack"、"skill_1"）
func _on_input_action(action: String) -> void:
	if input_disabled:
		return
	player_state_machine.send_event(action)

## 功能：移动方向变化时的回调，通知状态机切换移动/待机状态
## 参数：dir (Vector2) - 当前移动方向（单位向量）
func _on_movement_changed(dir: Vector2) -> void:
	if input_disabled:
		return
	if dir != Vector2.ZERO:
		_facing_direction = dir.normalized()
		player_state_machine.send_event("move")
	else:
		player_state_machine.send_event("idle")

# ========================== 公共 API 模块 ==========================
## 功能：停止玩家移动并禁用输入
## 说明：用于对话框、过场动画等需要暂时剥夺玩家控制权的场景
func disable_movement() -> void:
	movement_component.stop_immediately()
	set_physics_process(false)
	input_disabled = true

## 功能：恢复玩家移动与输入
func enable_movement() -> void:
	set_physics_process(true)
	input_disabled = false

# ========================== 信号回调模块 ==========================
## 功能：技能槽被鼠标点击时的回调，将槽位索引转换为动作名后发给状态机
## 参数：slot_index (int) - 技能槽索引（0~3）
func _on_skill_slot_clicked(slot_index: int) -> void:
	if input_disabled:
		return
	var action := "skill_%d" % [slot_index + 1]
	player_state_machine.send_event(action)

## 功能：受击框受到伤害时的回调，执行扣血并通知状态机进入受击状态
## 参数：hitbox (HitboxComponent) - 攻击来源的判定框组件
## 说明：若玩家已死亡则不再处理伤害
func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	if health_component.current_health <= 0:
		return
	health_component.take_damage(hitbox.damage)
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

## 功能：死亡动画播放完毕后的回调，打开游戏结束面板
func _on_player_died() -> void:
	UIManager.open_game_over()

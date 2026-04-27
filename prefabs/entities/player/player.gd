# prefabs/entities/player/player.gd
# 玩家核心脚本：处理8方向移动、状态管理、动画切换
# 挂载节点：Player (CharacterBody2D)
extends CharacterBody2D
class_name Player

# ========================== 导出参数（可在编辑器调整） ==========================
@export var stats_resource: Resource  # 在编辑器拖入 Stats 资源

# ========================== 节点引用（自动获取） ==========================
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var move_state_machine: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/MoveStateMachine/playback")
@onready var attack_component: AttackComponent = %AttackComponent
@onready var health_component: HealthComponent = $StatsComponents/HealthComponent
@onready var anim_controller: PlayerAnimationController = $PlayerAnimationController
@onready var movement_component: MovementComponent = $MovementComponent
@onready var player_state_machine: PlayerStateMachine = $PlayerStateMachine

# ========================== 全局变量 ==========================

var last_direction: Vector2 = Vector2.DOWN         # 记录最后朝向
var velocity_knockback: Vector2 = Vector2.ZERO     # 击退速度
var is_attacking: bool = false                     # 是否攻击

var _skill_runners: Dictionary = {}
# 技能槽配置（保留这 4 个预加载，作为技能槽的配置）
var _skill_slot_data: Array[SkillEffect] = [
	preload("res://resources/data/skills/initiator/slash_01.tres"),
	preload("res://resources/data/skills/initiator/slash_02.tres"),
	preload("res://resources/data/skills/finisher/pierce_01.tres"),
	preload("res://resources/data/skills/finisher/pierce_02.tres"),
]
const SKILL_SLOT_MAP: Dictionary = {
	"skill_1": 0,
	"skill_2": 1,
	"skill_3": 2,
	"skill_4": 3,
}

# ========================== 生命周期 ==========================
func _ready():
	health_component.connect("health_updated", _on_health_forward_to_bus)
	health_component.connect("unit_died", _on_died)
	# 立即发射信号刷新HUD显示，初始化顺序不可变
	health_component.setup(stats_resource)
	
	# 输入处理 – 仅转换信号为状态机命令
	InputManager.action_triggered.connect(_on_input_action)
	InputManager.movement_vector_changed.connect(_on_movement_changed)
	_init_state_machine()
	
	EventBus.skill_damage_requested.connect(_on_skill_damage_requested)
	EventBus.player_died.connect(_on_player_died)
	
	# 通过 InputManager 信号接收输入（替代直接每帧查询）
	print("Player: 初始化完成")

func _on_player_died() -> void:
	UIManager.open_game_over()

func _physics_process(delta: float):
	# 只在 idle/move 状态下更新移动
	if player_state_machine.current_state_name in ["idle", "move"]:
		var input_dir = InputManager.get_movement_vector()
		movement_component.update_movement(input_dir, delta)
		var move_dir = movement_component.get_movement_direction()
		if move_dir != Vector2.ZERO:
			last_direction = move_dir
	# 攻击/受击状态下保持 velocity 不变（由状态自己的 logic 控制）
	# 将方向传递给动画控制器
	anim_controller.set_movement_direction(last_direction)
	# 状态机更新 —— 改为调用状态机的 _process 机制，而非调用不存在的 update()
	# 这里改由 Godot 引擎自动调用 player_state_machine._process(delta)
	# 所以只需要：
	#   move_and_slide()

	move_and_slide()

func _on_input_action(action: String):
	# TODO 这里将所有的输入事件都派发给状态机，可是还有其他输入事件如ui_confirm_q、ui_cancel_e等状态机是处理不了的
	# 将所有输入事件派发给状态机，由当前状态决定是否响应
	player_state_machine.send_event(action)
	
func _on_movement_changed(dir: Vector2) -> void:
	# 只在 idle / move 状态下响应移动事件
	# 攻击/受击状态不响应，由状态自己的 on_event 决定
	if dir != Vector2.ZERO:
		player_state_machine.send_event("move")
	else:
		player_state_machine.send_event("idle")

func _init_state_machine() -> void:	
	# 创建持久化 SkillRunner 池
	for slot_data in _skill_slot_data:
		var runner = SkillRunner.new(slot_data, self)
		# 加入场景树
		add_child(runner)
		_skill_runners[slot_data.id] = runner
	
	var states = {
		"idle":     PlayerIdleState.new(),
		"move":     PlayerMoveState.new(),
		"attack":   PlayerAttackState.new(),
		"hurt":     PlayerHurtState.new(),
		"dead":     PlayerDeadState.new(),
		"recovery": PlayerRecoveryState.new(),
		"skill":    PlayerSkillState.new()
	}
	for state_name in states:
		states[state_name].setup(self)
		player_state_machine.add_state(state_name, states[state_name])
	
	player_state_machine.change_to("idle")

func get_skill_runner(skill_id: String) -> SkillRunner:
	return _skill_runners.get(skill_id)

func get_skill_data_by_action(action_name: String) -> SkillEffect:
	var idx = SKILL_SLOT_MAP.get(action_name, -1)
	if idx < 0 or idx >= _skill_slot_data.size():
		return null
	return _skill_slot_data[idx]

func get_target() -> Node:
	# TODO: 实现目标检测逻辑
	# 思路：检测前方扇形/圆形范围内最近的敌人
	# var space_state = get_world_2d().direct_space_state
	# var query = PhysicsRayQueryParameters2D.create(global_position, global_position + last_direction * 50)
	# var result = space_state.intersect_ray(query)
	# return result.collider if result else null
	return null

## 连接HurtboxComponent信号
func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	# 已死亡则不再处理
	if health_component.current_health <= 0:
		return
	health_component.take_damage(hitbox.damage)
	player_state_machine.send_event("hurt")

func _on_health_forward_to_bus(new_health: int, max_health: int) -> void:
	EventBus.health_updated.emit(new_health, max_health)

func _on_died() -> void:
	player_state_machine.send_event("dead")

func _on_skill_damage_requested(damage_data: Dictionary) -> void:
	var target = damage_data.get("target")
	var damage = damage_data.get("damage", 0)
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

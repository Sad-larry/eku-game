# prefabs/entities/player/player.gd
# 玩家核心脚本：处理8方向移动、状态管理、动画切换
# 挂载节点：Player (CharacterBody2D)
extends CharacterBody2D
class_name Player

# ========================== 导出参数（可在编辑器调整） ==========================
@export var move_speed: float = 200.0          # 移动速度
@export var attack_duration: float = 0.9       # 攻击动作时长

# ========================== 节点引用（自动获取） ==========================
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var move_state_machine: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/MoveStateMachine/playback")

# ========================== 状态枚举 ==========================
enum PlayerState {
	IDLE,       # 待机
	MOVE,       # 移动
	ATTACK,     # 攻击
	HURT,       # 受击
	DEAD        # 死亡
}

# ========================== 全局变量 ==========================
var current_state: PlayerState = PlayerState.IDLE  # 当前状态
var last_direction: Vector2 = Vector2.DOWN         # 记录最后朝向
var velocity_knockback: Vector2 = Vector2.ZERO     # 击退速度
var is_attacking: bool = false                     # 是否攻击

# ========================== 生命周期 ==========================
func _ready():
	anim_tree.active = true
	# 初始化状态
	_switch_state(PlayerState.IDLE)
	# 监听攻击动画结束
	anim_tree.animation_finished.connect(_on_attack_animation_finished)
	print("Player: 初始化完成")

func _physics_process(delta: float):
	# 死亡时停止所有逻辑
	if current_state == PlayerState.DEAD:
		return
		
	# 每帧强制更新动画方向（修复斜向不自然 + 动画错乱）
	_update_animation_direction()
	
	# 状态机核心
	match current_state:
		PlayerState.IDLE, PlayerState.MOVE:
			_handle_movement(delta)
		PlayerState.ATTACK:
			# 攻击时无法移动
			pass
		PlayerState.HURT:
			_handle_knockback(delta)
			
	move_and_slide()

# ========================== 核心：移动逻辑 ==========================
func _handle_movement(_delta: float):
	# 从全局输入管理器获取移动向量
	var input_dir: Vector2 = InputManager.get_movement_vector()
	
	# 8方向标准化（核心！修复斜向动画不自然）
	input_dir = normalize_8_direction(input_dir)
	
	# 处理攻击输入（缓冲输入）
	if InputManager.is_action_just_pressed("attack") and not is_attacking:
		_switch_state(PlayerState.ATTACK)
		return
		
	# 无输入 → 待机
	if input_dir == Vector2.ZERO:
		_switch_state(PlayerState.IDLE)
		velocity = Vector2.ZERO
		return

	# 有输入 → 移动
	last_direction = input_dir
	velocity = last_direction * move_speed
	_switch_state(PlayerState.MOVE)

# ========================== 8方向标准化（核心修复函数） =========================
func normalize_8_direction(dir: Vector2) -> Vector2:
	if dir.length() < 0.01:
		return Vector2.ZERO
	
	dir = dir.normalized()
	var angle = dir.angle()
	var eight_dir = [
		Vector2.RIGHT,
		Vector2(1, 1), # DOWN_RIGHT
		Vector2.DOWN,
		Vector2(1, -1), # DOWN_LEFT
		Vector2.LEFT,
		Vector2(-1, -1), # UP_LEFT
		Vector2.UP,
		Vector2(-1, 1) # UP_RIGHT
	]
	
	var closest = eight_dir[0]
	var min_diff = abs(angle - closest.angle())
	
	for v in eight_dir:
		var diff = abs(angle - v.angle())
		if diff < min_diff:
			min_diff = diff
			closest = v
	return closest

# ========================== 核心：状态管理 ==========================
func _switch_state(new_state: PlayerState) -> void:
	if new_state == current_state:
		return

	# 退出旧状态
	match current_state:
		PlayerState.ATTACK:
			is_attacking = false

	# 进入新状态
	current_state = new_state
	match new_state:
		PlayerState.IDLE:
			move_state_machine.travel("idle")
		PlayerState.MOVE:
			move_state_machine.travel("move")
		PlayerState.ATTACK:
			_perform_attack()
		PlayerState.HURT:
			move_state_machine.travel("hurt")
		PlayerState.DEAD:
			move_state_machine.travel("dead")
			
# ========================== 每帧更新方向（修复动画错乱） ==========================
func _update_animation_direction():
	anim_tree.set("parameters/MoveStateMachine/idle/blend_position", last_direction)
	anim_tree.set("parameters/MoveStateMachine/move/blend_position", last_direction)
	anim_tree.set("parameters/MoveStateMachine/attack/blend_position", last_direction)
	
# ========================== 攻击逻辑 ==========================
func _perform_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	move_state_machine.travel("attack")
	
	# 攻击自动结束
	await get_tree().create_timer(attack_duration).timeout
	if current_state == PlayerState.ATTACK:
		_switch_state(PlayerState.IDLE)
		
# ========================== 攻击动画结束 ==========================
func _on_attack_animation_finished(_anim_name: StringName):
	if current_state == PlayerState.ATTACK:
		_switch_state(PlayerState.IDLE)
		
# ========================== 受击与击退 ==========================
func take_damage(knockback_velocity: Vector2) -> void:
	if current_state == PlayerState.DEAD:
		return
	last_direction = knockback_velocity.bounce(Vector2.ONE).normalized()
	velocity_knockback = knockback_velocity
	_switch_state(PlayerState.HURT)
	
	await get_tree().create_timer(0.2).timeout
	if current_state != PlayerState.DEAD:
		_switch_state(PlayerState.IDLE)
	
func _handle_knockback(delta: float):
	velocity = velocity_knockback
	velocity_knockback = velocity_knockback.lerp(Vector2.ZERO, 5 * delta)

# ========================== 死亡 ==========================
func die():
	_switch_state(PlayerState.DEAD)
	velocity = Vector2.ZERO
	queue_free()

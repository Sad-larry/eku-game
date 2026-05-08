# ==============================================================================
#   chase_behavior.gd
#   功能：追逐技能行为。以冷却+持续模式运行，激活时临时提升敌人的
#        移动速度和攻击范围。移动逻辑仍由状态机的 move_state 处理，
#        ChaseBehavior 仅负责倍率的开关管理。
#
#   工作流程：
#       空闲（检测玩家）→ 满足条件 → 激活（设置倍率）
#       → 持续结束 → 重置倍率 → 冷却 → 回到空闲
# ==============================================================================
extends EnemyBehavior
class_name ChaseBehavior

# ========================== 导出变量模块 ==========================
## 行为冷却时间（秒）
@export var cooldown: float = 5.0

## 行为持续时间（秒）
@export var duration: float = 2.5

## 激活时的移动速度倍率（2.0 = 双倍速度）
@export var speed_multiplier: float = 2.0

## 激活时的攻击范围倍率（1.5 = 1.5 倍攻击距离）
@export var range_multiplier: float = 1.5

## 触发检测的玩家距离阈值（在此距离内才触发）
@export var trigger_distance: float = 180.0

# ========================== 内部变量模块 ==========================
## 当前阶段状态枚举
enum Phase { IDLE, ACTIVE, COOLDOWN }

var _phase: Phase = Phase.IDLE
var _phase_timer: float = 0.0

# ========================== 生命周期模块 ==========================
func _on_update(delta: float) -> void:
	match _phase:
		Phase.IDLE:
			_try_trigger()
		
		Phase.ACTIVE:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_deactivate()
		
		Phase.COOLDOWN:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_phase = Phase.IDLE

# ========================== 内部方法模块 ==========================
func _try_trigger() -> void:
	# 条件：玩家被检测到 + 在触发距离内 + 敌人存活
	if not enemy.player_detected:
		return
	if enemy.health_component.current_health <= 0:
		return
	
	var target = enemy.get_target()
	if target == null:
		return
	if enemy.global_position.distance_to(target.global_position) > trigger_distance:
		return
	
	_activate()

func _activate() -> void:
	_phase = Phase.ACTIVE
	_phase_timer = duration
	
	# 应用倍率
	enemy.speed_multiplier = speed_multiplier
	enemy.attack_range_multiplier = range_multiplier
	# 同步 Hitbox 尺寸（攻击范围已变）
	enemy._sync_hitbox_size()
	
	print("[ChaseBehavior] 激活: 移速 %.1fx, 攻击范围 %.1fx" % [speed_multiplier, range_multiplier])

func _deactivate() -> void:
	_phase = Phase.COOLDOWN
	_phase_timer = cooldown
	
	# 重置倍率
	enemy.speed_multiplier = 1.0
	enemy.attack_range_multiplier = 1.0
	enemy._sync_hitbox_size()
	
	print("[ChaseBehavior] 结束，进入冷却 %.1f 秒" % cooldown)

func _on_cleanup() -> void:
	# 死亡时确保倍率重置
	enemy.speed_multiplier = 1.0
	enemy.attack_range_multiplier = 1.0
	_phase = Phase.IDLE

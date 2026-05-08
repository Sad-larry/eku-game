# ==============================================================================
#   dash_behavior.gd
#   功能：闪避行为。当玩家靠近且敌人检测到即将被攻击时，
#        向后或侧向快速冲刺来躲避。
# ==============================================================================
extends EnemyBehavior
class_name DashBehavior

# ========================== 导出变量模块 ==========================
## 闪避冷却时间（秒）
@export var cooldown: float = 3.0

## 闪避冲刺速度（像素/秒）
@export var dash_speed: float = 300.0

## 闪避持续时间（秒）
@export var dash_duration: float = 0.3

## 触发闪避的玩家距离阈值
@export var trigger_distance: float = 40.0

# ========================== 内部变量模块 ==========================
var _cooldown_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _is_dashing: bool = false

# ========================== 生命周期模块 ==========================
func _on_update(delta: float) -> void:
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	
	if _is_dashing:
		_dash_timer -= delta
		# 冲锋期间直接控制速度
		enemy.velocity = _dash_direction * dash_speed
		enemy.move_and_slide()
		if _dash_timer <= 0.0:
			_is_dashing = false
			enemy.movement_component.stop_immediately()
		return
	
	# 冷却中或无敌意时跳过
	if _cooldown_timer > 0.0 or not enemy.player_detected:
		return
	
	# 检测玩家距离
	var target = enemy.get_target()
	if target == null:
		return
	var dist: float = enemy.global_position.distance_to(target.global_position)
	if dist > trigger_distance:
		return
	
	# 触发闪避：向后闪避
	_dash_direction = (enemy.global_position - target.global_position).normalized()
	_is_dashing = true
	_dash_timer = dash_duration
	_cooldown_timer = cooldown

func _on_cleanup() -> void:
	_is_dashing = false
	enemy.movement_component.stop_immediately()

# ==============================================================================
#   cooldown_state.gd
#   功能：敌人攻击冷却状态，在攻击完成后等待冷却时间结束，
#        然后根据玩家是否在检测范围内切换回追击或待机状态。
# ==============================================================================
extends EnemyState
class_name EnemyCooldownState

# ========================== 内部变量模块 ==========================
## 冷却剩余时间（秒）
var _cooldown_remaining: float = 0.0

# ========================== 状态生命周期模块 ==========================
func enter() -> void:
	super()
	get_anim().play_state("idle")
	
	_cooldown_remaining = _enemy.stats_resource.attack_cooldown

func exit() -> void:
	super()
	_cooldown_remaining = 0.0

func update(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	_cooldown_remaining -= delta
	if _cooldown_remaining > 0.0:
		return
	
	# 冷却结束，根据检测状态切换
	if _enemy.player_detected:
		state_machine.change_to("move")
	else:
		state_machine.change_to("idle")

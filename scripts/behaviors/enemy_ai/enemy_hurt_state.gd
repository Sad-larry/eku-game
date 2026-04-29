# ==============================================================================
#   hurt_state.gd
#   功能：敌人受击硬直状态，持续固定时长后根据玩家距离切换回追击或待机状态。
# ==============================================================================
extends EnemyState
class_name EnemyHurtState

# ========================== 内部变量模块 ==========================
## 受击硬直剩余时间（秒）
var _timer: float = 0.0

# ========================== 状态生命周期模块 ==========================
## 功能：进入受击状态时播放受击动画，并初始化硬直计时器
## 说明：需要 Enemy 类中存在 hurt_duration 属性（受击硬直时长）
func enter() -> void:
	play_animation("hurt")
	_timer = _enemy.hurt_duration

## 功能：每帧更新，倒计时硬直时间，结束后根据玩家是否在索敌范围内切换状态
## 参数：_delta (float) - 帧间隔时间（秒）
func update(_delta: float) -> void:
	_timer -= _delta
	if _timer <= 0.0:
		# 根据玩家是否在索敌范围内，切换到追击或待机状态
		state_machine.change_to(
			"chase" if is_player_in_range(_enemy.detection_range) else "idle"
		)

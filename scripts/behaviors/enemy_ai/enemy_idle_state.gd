# ==============================================================================
#   idle_state.gd
#   功能：敌人待机状态，播放待机动画，持续检测玩家距离，进入索敌范围时切换为追击状态。
# ==============================================================================
extends EnemyState
class_name EnemyIdleState

# ========================== 状态生命周期模块 ==========================
## 功能：进入待机状态时播放待机动画
func enter() -> void:
	play_animation("idle")

## 功能：每帧更新，检测玩家是否进入索敌范围
## 参数：_delta (float) - 帧间隔时间（秒，本状态中未直接使用）
func update(_delta: float) -> void:
	# 检测玩家是否在索敌范围内
	if is_player_in_range(_enemy.detection_range):
		# 范围内则切换到追击状态
		state_machine.change_to("chase")

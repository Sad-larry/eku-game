# ==============================================================================
#   hurt_state.gd
#   功能：玩家受击硬直状态，进入时播放受击动画，持续固定时长后自动切换回待机状态。
#        受击状态下不可被其他事件打断。
# ==============================================================================
extends PlayerState
class_name PlayerHurtState

# ========================== 内部变量模块 ==========================
## 受击硬直持续时间（秒）
var _hurt_duration: float = 0.2

## 受击状态剩余计时器（秒）
var _timer: float = 0.0

# ========================== 状态生命周期模块 ==========================
## 功能：进入受击状态时初始化计时器并播放受击动画
func enter() -> void:
	_timer = _hurt_duration
	get_anim().play_state("hurt")

## 功能：每物理帧更新，倒计时硬直时间，结束后切换回待机状态
## 参数：delta (float) - 物理帧间隔时间（秒）
func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.change_to("idle")
		return

# ========================== 事件处理模块 ==========================
## 功能：受击状态不可被其他事件打断
## 参数：_event_name (String) - 事件名称（未使用）
func on_event(_event_name: String) -> void:
	pass  # 受击状态不可打断

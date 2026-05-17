# ==============================================================================
#   player_hurt_state.gd
#   功能：玩家受击硬直状态，播放受击动画，持续固定时长后自动回到待机。
# ==============================================================================
extends PlayerState
class_name PlayerHurtState

# ========================== 变量定义模块 ==========================
## 受击硬直持续时间（秒）
var _hurt_duration: float = 0.2
## 硬直计时器
var _timer: float = 0.0

# ========================== 生命周期模块 ==========================
## 功能：进入受击状态时初始化计时器并播放受击动画
func enter() -> void:
	_timer = _hurt_duration
	get_anim().play_anim("hurt", player.last_direction)

## 功能：每物理帧更新硬直计时器，时间结束后切换到待机状态
## 参数：delta (float) - 物理帧间隔时间（秒）
func physics_update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.change_to("idle")

## 功能：响应状态事件（受击状态不响应其他事件）
## 参数：_event_name (String) - 事件名称（未使用）
func on_event(_event_name: String) -> void:
	pass

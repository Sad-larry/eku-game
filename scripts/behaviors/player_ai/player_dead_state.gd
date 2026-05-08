# ==============================================================================
#   dead_state.gd
#   功能：玩家死亡状态，播放死亡动画、禁止物理/逻辑处理、等待动画完成后
#        发射玩家死亡信号并销毁玩家节点。
# ==============================================================================
extends PlayerState
class_name PlayerDeadState

# ========================== 状态生命周期模块 ==========================
## 功能：进入死亡状态时播放死亡动画、停止移动、禁用处理循环
func enter() -> void:
	# 调用父类 enter 方法（设置 _is_active = true）
	super()
	get_anim().play_state("dead")
	_player.velocity = Vector2.ZERO
	
	# 禁用玩家的处理函数（可选，防止死亡后仍有物理响应）
	_player.set_process(false)
	_player.set_physics_process(false)
	
	# 等待死亡动画播放完成（替代硬编码计时器）
	var finished_state = await get_anim().anim_finished
	
	# 安全检查：确保等待到的确实是 "dead" 状态的动画信号，且当前状态仍处于激活状态
	if finished_state != "dead" or not _is_active:
		return
	
	# TODO: 发射一个 died_animation_finished 信号，供外部系统清理引用
	#       当前直接发射 player_died 全局事件
	EventBus.player_died.emit()
	
	# 销毁玩家节点
	_player.queue_free()

# ========================== 事件处理模块 ==========================
## 功能：死亡状态不可被任何事件打断
## 参数：_event_name (String) - 事件名称（未使用）
func on_event(_event_name: String) -> void:
	pass  # 死亡状态不可打断，忽略所有事件

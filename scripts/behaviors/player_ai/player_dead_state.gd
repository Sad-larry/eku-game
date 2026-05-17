# ==============================================================================
#   player_dead_state.gd
#   功能：玩家死亡状态，播放死亡动画、禁止物理/逻辑处理、
#        通过信号监听动画完成，完成后发射死亡信号并销毁玩家节点。
# ==============================================================================
extends PlayerState
class_name PlayerDeadState

# ========================== 生命周期模块 ==========================
## 功能：进入死亡状态时播放死亡动画并禁用玩家处理
func enter() -> void:
	super()
	get_anim().play_anim("dead", player.last_direction)
	player.velocity = Vector2.ZERO
	player.set_process(false)
	player.set_physics_process(false)

	# 连接动画完成信号，替代 await 模式（更健壮，不会因动画缺失而悬挂）
	if not get_anim().anim_finished.is_connected(_on_death_anim_finished):
		get_anim().anim_finished.connect(_on_death_anim_finished)

## 功能：退出死亡状态时断开动画完成信号连接
func exit() -> void:
	super()
	# 退出时断开连接，防止状态复用导致信号重复触发
	if get_anim().anim_finished.is_connected(_on_death_anim_finished):
		get_anim().anim_finished.disconnect(_on_death_anim_finished)

## 功能：死亡动画播放完成时的回调
func _on_death_anim_finished() -> void:
	if state_name != "dead" or not _is_active:
		return
	EventBus.player_died.emit()
	player.queue_free()

## 功能：响应状态事件（死亡状态不响应其他事件）
## 参数：_event_name (String) - 事件名称（未使用）
func on_event(_event_name: String) -> void:
	pass

# ==============================================================================
#   player_dead_state.gd
#   功能：玩家死亡状态，播放死亡动画、禁止物理/逻辑处理、
#        通过信号监听动画完成，完成后发射死亡信号并销毁玩家节点。
# ==============================================================================
extends PlayerState
class_name PlayerDeadState

func enter() -> void:
	super()
	get_anim().play_anim("dead", player.last_direction)
	player.velocity = Vector2.ZERO
	player.set_process(false)
	player.set_physics_process(false)

	# 连接动画完成信号，替代 await 模式（更健壮，不会因动画缺失而悬挂）
	if not get_anim().anim_finished.is_connected(_on_death_anim_finished):
		get_anim().anim_finished.connect(_on_death_anim_finished)

func exit() -> void:
	super()
	# 退出时断开连接，防止状态复用导致信号重复触发
	if get_anim().anim_finished.is_connected(_on_death_anim_finished):
		get_anim().anim_finished.disconnect(_on_death_anim_finished)

func _on_death_anim_finished() -> void:
	if state_name != "dead" or not _is_active:
		return
	EventBus.player_died.emit()
	player.queue_free()

func on_event(_event_name: String) -> void:
	pass

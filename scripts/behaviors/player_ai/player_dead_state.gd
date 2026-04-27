# player/states/dead_state.gd
extends PlayerState
class_name PlayerDeadState

func enter() -> void:
	super()
	_player.anim_controller.play_state("dead")
	_player.velocity = Vector2.ZERO
	# 禁用碰撞等（可选）
	_player.set_process(false)
	_player.set_physics_process(false)
	# 等待死亡动画播放完毕（替代硬编码 1.5s timer）
	var finished_state = await _player.anim_controller.animation_finished
	# 安全过滤：确保等到的确实是 "dead" 的动画信号
	if finished_state != "dead" or not _is_active:
		return
	# TODO 发射一个 died_animation_finished 信号，供外部系统清理引用
	EventBus.player_died.emit()
	_player.queue_free()

func on_event(_event_name: String) -> void:
	pass  # 死亡状态不可打断

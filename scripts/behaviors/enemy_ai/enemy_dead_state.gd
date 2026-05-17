# ==============================================================================
#   enemy_dead_state.gd
#   功能：敌人死亡状态，播放死亡动画后销毁敌人节点。
#        可扩展添加死亡特效、掉落物等逻辑。
# ==============================================================================
extends EnemyState
class_name EnemyDeadState

# ========================== 状态生命周期模块 ==========================
## 功能：进入死亡状态时播放死亡动画，并标记敌人待销毁
## 说明：当前实现为立即销毁（未等待动画完成），如需等待动画，可启用注释的定时器
func enter() -> void:
	# 调用父类 enter 方法（设置 _is_active = true）
	super()
	get_anim().play_state("dead")
	# 等待死亡动画播放完成（替代硬编码计时器）
	var finished_state = await get_anim().anim_finished
	# 安全检查：确保等待到的确实是 "dead" 状态的动画信号，且当前状态仍处于激活状态
	if finished_state != "dead" or not _is_active:
		return
	
	# 从场景树中移除敌人节点
	_enemy.queue_free()

# ==============================================================================
#   enemy_hurt_state.gd
#   功能：敌人受击硬直状态，持续固定时长后根据玩家距离切换回追击或待机状态。
# ==============================================================================
extends EnemyState
class_name EnemyHurtState

# ========================== 状态生命周期模块 ==========================
## 功能：进入受击状态时播放受击动画，并初始化硬直计时器
## 说明：需要 Enemy 类中存在 hurt_duration 属性（受击硬直时长）
func enter() -> void:
	# 调用父类 enter 方法（设置 _is_active = true）
	super()
	get_anim().play_state("hurt")
	# 等待死亡动画播放完成（替代硬编码计时器）
	var finished_state = await get_anim().anim_finished
	# 安全检查：确保等待到的确实是 "hurt" 状态的动画信号，且当前状态仍处于激活状态
	if finished_state != "hurt" or not _is_active:
		return
	state_machine.change_to("idle")

# ========================== 事件处理模块 ==========================
## 功能：受击状态不可被其他事件打断
## 参数：_event_name (String) - 事件名称（未使用）
func on_event(_event_name: String) -> void:
	pass  # 受击状态不可打断

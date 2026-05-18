# ==============================================================================
#   enemy_dead_state.gd
#   功能：敌人死亡状态，播放死亡动画后淡出并销毁敌人节点。
# ==============================================================================
extends EnemyState
class_name EnemyDeadState

# ========================== 常量定义模块 ==========================
## 淡出持续时间（秒）
const FADE_DURATION: float = 0.3

# ========================== 状态生命周期模块 ==========================
## 功能：进入死亡状态时播放死亡动画，淡出后销毁
func enter() -> void:
	super()
	get_anim().play_state("dead")
	var finished_state = await get_anim().anim_finished
	if finished_state != "dead" or not _is_active:
		return

	# 淡出效果
	var sprite := _enemy.anim_controller.sprite
	if is_instance_valid(sprite):
		var tween: Tween = _enemy.create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, FADE_DURATION)
		await tween.finished

	_enemy.queue_free()

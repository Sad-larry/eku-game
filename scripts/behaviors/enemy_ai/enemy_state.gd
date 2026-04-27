# scripts/behaviors/enemy_ai/enemy_state.gd
extends FSMState
class_name EnemyState

# 子状态通过这个方法获取引用
var _enemy: Enemy

func setup(e: Enemy) -> void:
	_enemy = e

# 辅助方法：消除各状态中重复的 _play_animation()
func play_animation(anim_name: String) -> void:
	if _enemy and _enemy.has_method("play_anim"):
		_enemy.play_anim(anim_name)

# 辅助方法：获取距离判断
func is_player_in_range(_range_val: float) -> bool:
	# 委托给 Enemy 的计算方法，或直接用全局坐标
	return false  # 伪代码占位

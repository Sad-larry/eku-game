# ==============================================================================
#   enemy_state.gd
#   功能：敌人状态基类，继承自 FSMState，为所有敌人具体状态（待机、追击、攻击等）
#        提供通用的辅助方法（获取敌人引用、播放动画、距离检测等），减少子类重复代码。
# ==============================================================================
extends FSMState
class_name EnemyState

# ========================== 内部变量模块 ==========================
## 宿主敌人实例引用（需通过 setup() 方法注入）
var _enemy: Enemy

# ========================== 公共 API 模块 ==========================
## 功能：设置敌人引用，供状态机初始化时调用
## 参数：e (Enemy) - 敌方实体实例
func setup(e: Enemy) -> void:
	_enemy = e

## 功能：获取敌人的动画控制器组件
## 返回值：EnemyAnimationController - 动画控制器实例
func get_anim() -> EnemyAnimationController:
	return _enemy.anim_controller
	
## 功能：获取敌人的移动组件
## 返回值：EnemyMovementComponent - 移动组件实例
func get_movement() -> EnemyMovementComponent:
	return _enemy.movement_component

## 功能：判断玩家是否在指定范围内（占位实现）
## 参数：_range_val (float) - 检测半径范围（像素）
## 返回值：bool - 是否存在玩家且在范围内（当前返回 false，待子类或后续实现）
func is_player_in_range(range_val: float) -> bool:
	var target: Node2D = _enemy.get_target()
	if target == null:
		return false
	var dist: float = _enemy.global_position.distance_to(target.global_position)
	return dist <= range_val

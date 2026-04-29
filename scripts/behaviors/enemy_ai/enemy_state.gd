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

## 功能：播放敌人动画（委托给 Enemy.play_anim 方法）
## 参数：anim_name (String) - 动画名称（如 "idle"、"run"、"attack"）
## 说明：若 _enemy 有效且存在 play_anim 方法，则调用之
func play_animation(anim_name: String) -> void:
	if _enemy and _enemy.has_method("play_anim"):
		_enemy.play_anim(anim_name)

## 功能：判断玩家是否在指定范围内（占位实现）
## 参数：_range_val (float) - 检测半径范围（像素）
## 返回值：bool - 是否存在玩家且在范围内（当前返回 false，待子类或后续实现）
## TODO: 实际实现需要获取玩家坐标并与敌人自身坐标进行距离计算
func is_player_in_range(_range_val: float) -> bool:
	# 伪代码占位，具体逻辑需在各状态子类中实现或在此处统一实现
	return false

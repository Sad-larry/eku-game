# ==============================================================================
#   cooldown_state.gd
#   功能：敌人攻击冷却状态，攻击后进入等待时间，冷却结束后切换回追击状态。
# ==============================================================================
extends EnemyState
class_name EnemyCooldownState

# ========================== 内部变量模块 ==========================
## 冷却剩余时间（秒）
var _timer: float = 0.0

# ========================== 状态生命周期模块 ==========================
## 功能：进入冷却状态时，初始化计时器为敌人的攻击冷却时长
## 说明：需要 Enemy 类中存在 attack_cooldown 属性
func enter() -> void:
	_timer = _enemy.attack_cooldown

## 功能：每帧更新，倒计时冷却时间，归零时切换回追击状态
## 参数：_delta (float) - 帧间隔时间（秒）
func update(_delta: float) -> void:
	_timer -= _delta
	if _timer <= 0.0:
		state_machine.change_to("chase")

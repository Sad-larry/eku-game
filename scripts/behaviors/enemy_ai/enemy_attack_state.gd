# ==============================================================================
#   attack_state.gd
#   功能：敌人攻击状态，进入时播放攻击动画、执行攻击逻辑，完成后立即切换至冷却状态。
#        属于 EnemyStateMachine 的状态节点之一。
# ==============================================================================
extends EnemyState
class_name EnemyAttackState

# ========================== 内部变量模块 ==========================
## 标记是否已执行过攻击逻辑（防止重复执行）
var _performed: bool = false

# ========================== 状态生命周期模块 ==========================
## 功能：进入攻击状态时的初始化逻辑
## 说明：重置攻击执行标记、播放攻击动画、触发攻击逻辑、完成后切换到冷却状态
func enter() -> void:
	_performed = false
	play_animation("attack")
	
	# 执行攻击逻辑（可委托给 Enemy.attack() 或独立的 AttackComponent）
	_enemy.attack()
	_performed = true
	
	# 攻击动作完成后立即进入冷却状态（等待冷却时间结束后再循环）
	state_machine.change_to("cooldown")

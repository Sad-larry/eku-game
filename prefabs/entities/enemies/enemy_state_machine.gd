# scripts/behaviors/enemy_ai/enemy_state_machine.gd
extends StateMachine
class_name EnemyStateMachine

# 只做三件事：
# 1. 持有敌人引用
var enemy: Enemy = null

# 2. 工厂方法：创建所有状态并注册
func init_states(e: Enemy) -> void:
	enemy = e
	var all = {
		"idle":     EnemyIdleState.new(),
		"chase":    EnemyChaseState.new(),
		"attack":   EnemyAttackState.new(),
		"hurt":     EnemyHurtState.new(),
		"cooldown": EnemyCooldownState.new(),
		"dead":     EnemyDeadState.new(),
	}
	for state_name in all:
		all[state_name].setup(e)
		add_state(state_name, all[state_name])
	change_to("idle")

# 3. 事件转发：供外部（Enemy.gd）调用
func send_event(event: String) -> void:
	# 委托给当前状态的 on_event()
	if _current_state and _current_state.has_method("on_event"):
		_current_state.on_event(event)

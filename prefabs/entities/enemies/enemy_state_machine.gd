# ==============================================================================
#   enemy_state_machine.gd
#   功能：敌人状态机，继承自通用 StateMachine 类，负责持有敌人引用、
#        创建并注册所有敌人状态（待机、追击、攻击、受击、冷却、死亡），
#        提供事件转发接口供外部（如 Enemy.gd）调用。
# ==============================================================================
extends StateMachine
class_name EnemyStateMachine

# ========================== 变量定义模块 ==========================
## 宿主敌人实例引用（通过 init_states 注入）
var enemy: Enemy = null

# ========================== 公共 API 模块 ==========================
## 功能：初始化状态机，创建所有状态并注册，初始切换至待机状态
## 参数：e (Enemy) - 敌方实体实例
func init_states(e: Enemy) -> void:
	enemy = e
	
	# 创建所有状态实例
	var all = {
		"idle":     EnemyIdleState.new(),
		"chase":    EnemyChaseState.new(),
		"attack":   EnemyAttackState.new(),
		"hurt":     EnemyHurtState.new(),
		"cooldown": EnemyCooldownState.new(),
		"dead":     EnemyDeadState.new(),
	}
	
	# 为每个状态注入敌人引用，并注册到状态机
	for state_name in all:
		all[state_name].setup(e)
		add_state(state_name, all[state_name])
	
	# 启动状态机，初始状态为待机
	change_to("idle")

## 功能：向当前状态发送事件（如 "hurt"、"attack" 等）
## 参数：event (String) - 事件名称
## 说明：委托给当前状态的 on_event() 方法（若该方法存在）
func send_event(event: String) -> void:
	if _current_state and _current_state.has_method("on_event"):
		_current_state.on_event(event)

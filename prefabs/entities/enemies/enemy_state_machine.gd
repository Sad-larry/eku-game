# ==============================================================================
#   enemy_state_machine.gd
#   功能：敌人状态机，继承自通用 StateMachine 类，负责持有敌人引用、
#        创建并注册所有敌人状态（待机、追击、攻击、受击、冷却、死亡），
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
	entity_name = "Enemy(%s)" % enemy.name
	
	# 创建所有状态实例
	var all = {
		"idle":     EnemyIdleState.new(),
		"move":     EnemyMoveState.new(),
		"attack":   EnemyAttackState.new(),
		"hurt":     EnemyHurtState.new(),
		"skill":    EnemySkillState.new(),
		"cooldown": EnemyCooldownState.new(),
		"dead":     EnemyDeadState.new(),
	}
	
	# 为每个状态注入敌人引用，并注册到状态机
	for state_name in all:
		all[state_name].setup(enemy)
		add_state(state_name, all[state_name])
	
	# 启动状态机，初始状态为待机
	change_to("idle")

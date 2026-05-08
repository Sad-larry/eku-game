# ==============================================================================
#   PlayerStateMachine.gd
#   功能：玩家状态机类（当前为空实现），继承自通用的 StateMachine 基类，
#        用于管理玩家的各种状态（idle、move、attack、hurt、dead、recovery、skill 等）。
#        具体的状态注册和切换逻辑在 Player.init_state_machine() 中完成。
# ==============================================================================
extends StateMachine
class_name PlayerStateMachine

# ========================== 变量定义模块 ==========================
## 玩家实例引用（通过 init_states 注入）
var player: Player = null

# ========================== 公共 API 模块 ==========================
## 功能：初始化状态机，创建所有状态并注册，初始切换至待机状态
## 参数：p (Player) - 玩家实体实例
func init_states(p: Player) -> void:
	player = p
	entity_name = "Player(%s)" % player.name
	
	# 创建所有状态实例并注册到状态机
	var states = {
		"idle":     PlayerIdleState.new(),
		"move":     PlayerMoveState.new(),
		"attack":   PlayerAttackState.new(),
		"hurt":     PlayerHurtState.new(),
		"dead":     PlayerDeadState.new(),
		"recovery": PlayerRecoveryState.new(),
		"skill":    PlayerSkillState.new()
	}
	for state_name in states:
		states[state_name].setup(player)
		add_state(state_name, states[state_name])
	
	# 启动状态机，初始状态为待机
	change_to("idle")

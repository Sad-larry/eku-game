# ==============================================================================
#   player_state_machine.gd
#   功能：玩家状态机，继承自 StateMachine。
#        在 _ready() 中自动扫描场景中已挂载的子节点（PlayerState 实例），
#        注入 player/state_machine 引用并注册到状态字典中。
#   说明：状态节点已在场景编辑器中预先挂载到 StateMachine 节点下，
#        不再调用 add_state()（该方法内含 add_child() 会产生重复挂载）。
# ==============================================================================
extends StateMachine
class_name PlayerStateMachine

## 功能：扫描子节点中的 PlayerState 实例，注入依赖并注册到状态字典。
## 说明：
##   - 状态实例已在场景编辑器中挂载好，此处仅做引用注入和注册，
##     不需要 add_child()，避免重复挂载。
##   - 使用 call_deferred 延迟切换初始状态，原因：Player 的 @onready
##     变量（如 anim_controller）要在 Player._ready() 之前才解析，
##     而 _ready() 自底向上调用，PlayerStateMachine._ready() 先于
##     Player._ready() 执行，此时访问 player.anim_controller 会得到 null。
##     延迟一帧可确保所有父节点的 @onready 均已就绪。
func _ready() -> void:
	var player := get_parent() as Player
	entity_name = player.name

	for child in get_children():
		if child is PlayerState:
			var state := child as PlayerState
			state.player = player
			state.state_machine = self
			# 直接注册到 _states 字典
			_states[state.state_name] = state

	# 延迟切换初始状态，等待 Player 的 @onready 变量解析完毕
	call_deferred("change_to", "idle")

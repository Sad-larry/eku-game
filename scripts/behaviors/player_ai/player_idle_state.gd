# ==============================================================================
#   player_idle_state.gd
#   功能：玩家待机状态，播放待机动画，响应移动/攻击/受击/死亡/技能事件。
# ==============================================================================
extends PlayerState
class_name PlayerIdleState

# ========================== 生命周期模块 ==========================
## 功能：进入待机状态时播放待机动画
func enter() -> void:
	get_anim().play_anim("idle", player.last_direction)

## 功能：响应状态事件，根据事件类型切换到对应状态
## 参数：event_name (String) - 事件名称（如 "move"、"attack"、"hurt" 等）
func on_event(event_name: String) -> void:
	match event_name:
		"move":
			state_machine.change_to("move")
		"attack":
			state_machine.change_to("attack")
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")
		"skill_1", "skill_2", "skill_3", "skill_4":
			_transition_to_skill(event_name)

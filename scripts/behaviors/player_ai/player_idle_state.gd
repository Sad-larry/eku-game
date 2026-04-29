# ==============================================================================
#   idle_state.gd
#   功能：玩家待机状态，播放待机动画，响应移动、攻击、受击、死亡、技能等事件，
#        根据事件类型切换到对应的状态。
# ==============================================================================
extends PlayerState
class_name PlayerIdleState

# ========================== 状态生命周期模块 ==========================
## 功能：进入待机状态时播放待机动画
func enter() -> void:
	_player.anim_controller.play_state("idle")
	# 可选：立即停止移动（若上一状态有惯性）
	# _player.movement_component.stop_immediately()

# ========================== 事件处理模块 ==========================
## 功能：待机状态中接收到事件时的回调
## 参数：event_name (String) - 事件名称（如 "move"、"attack"、"hurt"、"dead"、"skill_X"）
func on_event(event_name: String) -> void:
	match event_name:
		"move":
			# 移动输入 → 切换到移动状态
			state_machine.change_to("move")
		"attack":
			# 攻击输入 → 切换到攻击状态
			state_machine.change_to("attack")
		"hurt":
			# 受击事件 → 切换到受击状态
			state_machine.change_to("hurt")
		"dead":
			# 死亡事件 → 切换到死亡状态
			state_machine.change_to("dead")
		"skill_1", "skill_2", "skill_3", "skill_4":
			# 技能输入 → 切换到技能状态（通过辅助方法）
			_transition_to_skill(event_name)

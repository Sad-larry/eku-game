# ==============================================================================
#   player_move_state.gd
#   功能：玩家移动状态，播放移动动画，响应待机/攻击/受击/死亡/技能事件。
#        每帧检测方向变化并更新动画，确保斜向移动时正确播放对应动画。
# ==============================================================================
extends PlayerState
class_name PlayerMoveState

# ========================== 变量定义模块 ==========================
## 上一帧动画使用的方向，用于检测方向变化避免重复设置动画
var _last_anim_dir: Vector2 = Vector2.ZERO

# ========================== 生命周期模块 ==========================
## 功能：进入移动状态时初始化动画方向
func enter() -> void:
	_last_anim_dir = Vector2.ZERO
	_update_move_anim(player.last_direction)

## 功能：每帧检测方向变化并更新移动动画
## 说明：玩家在移动中改变方向（如从下变为左下）时，last_direction
##       会在 _physics_process 中更新，此处每帧检查并更新动画。
## 参数：_delta (float) - 帧间隔时间（秒，未使用）
func update(_delta: float) -> void:
	_update_move_anim(player.last_direction)

## 功能：响应状态事件，根据事件类型切换到对应状态
## 参数：event_name (String) - 事件名称（如 "idle"、"attack" 等）
func on_event(event_name: String) -> void:
	match event_name:
		"idle":
			state_machine.change_to("idle")
		"attack":
			state_machine.change_to("attack")
		"hurt":
			state_machine.change_to("hurt")
		"dead":
			state_machine.change_to("dead")
		"skill_1", "skill_2", "skill_3", "skill_4":
			_transition_to_skill(event_name)

# ========================== 内部方法模块 ==========================
## 功能：当方向变化时更新动画，避免重复调用 play_anim
## 参数：direction (Vector2) - 当前面朝方向
func _update_move_anim(direction: Vector2) -> void:
	if direction == _last_anim_dir:
		return
	_last_anim_dir = direction
	get_anim().play_anim("move", direction)

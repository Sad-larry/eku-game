# ==============================================================================
#   enrage_behavior.gd
#   功能：狂暴行为。低血量时提升攻击力和移速（一次性触发）。
# ==============================================================================
class_name EnrageBehavior extends TriggerableBehavior

@export var speed_boost: float = 1.5
@export var damage_boost: float = 1.5

var _is_enraged: bool = false

func _execute_behavior() -> void:
	if _is_enraged or enemy == null:
		return
	_is_enraged = true
	enemy.speed_multiplier *= speed_boost
	# 视觉反馈：变红
	if enemy.anim_controller and enemy.anim_controller.sprite:
		enemy.anim_controller.sprite.modulate = Color(1.5, 0.3, 0.3, 1)

	if Global.DEBUG_MODE:
		print("[EnrageBehavior] ", enemy.name, " 进入狂暴状态")

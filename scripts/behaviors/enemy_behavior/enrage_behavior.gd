# ==============================================================================
#   enrage_behavior.gd
#   功能：狂暴行为。低血量时提升攻击力和移速。
# ==============================================================================
class_name EnrageBehavior extends EnemyBehavior

@export var trigger_hp_pct: float = 0.3
@export var speed_boost: float = 1.5
@export var damage_boost: float = 1.5

var _is_enraged: bool = false

func _on_setup() -> void:
	pass

func _on_update(_delta: float) -> void:
	if _is_enraged or enemy == null:
		return

	var hp_pct := float(enemy.health_component.current_health) / enemy.health_component.max_health
	if hp_pct <= trigger_hp_pct:
		_activate_enrage()

func _activate_enrage() -> void:
	_is_enraged = true
	enemy.speed_multiplier *= speed_boost
	# 视觉反馈：变红
	if enemy.anim_controller and enemy.anim_controller.sprite:
		enemy.anim_controller.sprite.modulate = Color(1.5, 0.3, 0.3, 1)

	if Global.DEBUG_MODE:
		print("[EnrageBehavior] ", enemy.name, " 进入狂暴状态")

# ==============================================================================
#   always_trigger.gd
#   功能：无条件触发器。每帧都返回 true，用于持续性行为。
# ==============================================================================
class_name AlwaysTrigger
extends BehaviorTrigger

# ========================== 公共 API ==========================
func is_triggered(_context: Dictionary) -> bool:
	return true

func reset() -> void:
	pass

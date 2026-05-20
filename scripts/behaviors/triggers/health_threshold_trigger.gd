# ==============================================================================
#   health_threshold_trigger.gd
#   功能：血量阈值触发器。当生命值百分比低于阈值时触发（一次性）。
# ==============================================================================
class_name HealthThresholdTrigger
extends BehaviorTrigger

# ========================== 导出变量 ==========================
## 血量阈值（0.0-1.0），低于此值时触发
@export var health_threshold: float = 0.3

# ========================== 运行时状态 ==========================
var _triggered: bool = false

# ========================== 公共 API ==========================
func is_triggered(context: Dictionary) -> bool:
	if _triggered:
		return false
	var health_pct: float = context.get("health_pct", 1.0)
	if health_pct <= health_threshold:
		_triggered = true
		return true
	return false

func reset() -> void:
	_triggered = false

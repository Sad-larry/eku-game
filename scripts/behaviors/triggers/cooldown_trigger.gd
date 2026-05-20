# ==============================================================================
#   cooldown_trigger.gd
#   功能：冷却时间触发器。每隔指定时间触发一次。
# ==============================================================================
class_name CooldownTrigger
extends BehaviorTrigger

# ========================== 导出变量 ==========================
## 冷却时间（秒）
@export var cooldown: float = 5.0

# ========================== 运行时状态 ==========================
var _timer: float = 0.0

# ========================== 公共 API ==========================
func is_triggered(context: Dictionary) -> bool:
	var delta: float = context.get("delta", 0.0)
	_timer -= delta
	if _timer <= 0.0:
		_timer = cooldown
		return true
	return false

func reset() -> void:
	_timer = 0.0

# ==============================================================================
#   phase_trigger.gd
#   功能：Boss阶段触发器。当Boss进入指定阶段时触发（一次性）。
# ==============================================================================
class_name PhaseTrigger
extends BehaviorTrigger

# ========================== 导出变量 ==========================
## 目标阶段索引（从0开始）
@export var phase_index: int = 0

# ========================== 运行时状态 ==========================
var _triggered: bool = false

# ========================== 公共 API ==========================
func is_triggered(context: Dictionary) -> bool:
	if _triggered:
		return false
	var boss_phase: int = context.get("boss_phase", -1)
	if boss_phase >= phase_index:
		_triggered = true
		return true
	return false

func reset() -> void:
	_triggered = false

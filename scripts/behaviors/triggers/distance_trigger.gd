# ==============================================================================
#   distance_trigger.gd
#   功能：距离触发器。当玩家距离在指定范围内时触发。
# ==============================================================================
class_name DistanceTrigger
extends BehaviorTrigger

# ========================== 导出变量 ==========================
## 最小距离（像素），0 表示无下限
@export var min_distance: float = 0.0

## 最大距离（像素）
@export var max_distance: float = 200.0

# ========================== 公共 API ==========================
func is_triggered(context: Dictionary) -> bool:
	var player_distance: float = context.get("player_distance", INF)
	return player_distance >= min_distance and player_distance <= max_distance

func reset() -> void:
	pass

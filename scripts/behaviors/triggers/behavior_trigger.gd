# ==============================================================================
#   behavior_trigger.gd
#   功能：行为触发器基类。控制 EnemyBehavior 何时被激活。
#        子类实现不同的触发条件（冷却、血量、距离、阶段等）。
#   设计：继承 Resource，可在检查器中配置并序列化。
# ==============================================================================
class_name BehaviorTrigger
extends Resource

# ========================== 公共 API ==========================
## 功能：检查触发条件是否满足
## 参数：context - 运行时上下文（delta、health_pct、player_distance 等）
## 返回：true 表示条件满足，应执行行为
func is_triggered(_context: Dictionary) -> bool:
	return false

## 功能：重置触发器状态（用于一次性触发器的重新激活）
func reset() -> void:
	pass

# ==============================================================================
#   keep_distance_behavior.gd
#   功能：保持距离行为。当玩家距离过近时后退，过远时前进。
# ==============================================================================
extends TriggerableBehavior
class_name KeepDistanceBehavior

# ========================== 导出变量 ==========================
## 最小安全距离（像素），低于此距离后退
@export var min_distance: float = 100.0

## 最大追击距离（像素），高于此距离前进
@export var max_distance: float = 200.0

# ========================== 行为执行 ==========================
func _execute_behavior() -> void:
	if enemy == null:
		return

	var target := enemy.get_target()
	if target == null:
		return

	var dist: float = enemy.global_position.distance_to(target.global_position)
	var direction: Vector2 = Vector2.ZERO

	if dist < min_distance:
		direction = (enemy.global_position - target.global_position).normalized()
	elif dist > max_distance:
		direction = (target.global_position - enemy.global_position).normalized()

	if direction != Vector2.ZERO:
		enemy.velocity = direction * enemy.get_speed()
		enemy.move_and_slide()
	else:
		enemy.velocity = Vector2.ZERO

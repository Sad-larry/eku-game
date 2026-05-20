# ==============================================================================
#   shoot_behavior.gd
#   功能：远程射击行为。以固定时间间隔向玩家发射投掷物。
# ==============================================================================
extends TriggerableBehavior
class_name ShootBehavior

# ========================== 导出变量 ==========================
## 投掷物预制体
@export var projectile_scene: PackedScene

## 发射位置（相对于敌人的偏移）
@export var muzzle_offset: Vector2 = Vector2(16, 0)

# ========================== 行为执行 ==========================
func _execute_behavior() -> void:
	if projectile_scene == null or enemy == null:
		return
	_shoot()

func _shoot() -> void:
	# 实例化投掷物
	var projectile: Node2D = projectile_scene.instantiate()
	if projectile == null:
		return

	# 计算发射位置
	var dir: float = signf(enemy.anim_controller.sprite.scale.x)
	var spawn_pos: Vector2 = enemy.global_position + Vector2(muzzle_offset.x * dir, muzzle_offset.y)

	projectile.global_position = spawn_pos
	if projectile.has_method("launch"):
		var target_dir: Vector2 = Vector2(dir, 0)
		if enemy.get_target():
			target_dir = (enemy.get_target().global_position - spawn_pos).normalized()
		projectile.launch(target_dir)

	enemy.get_parent().add_child(projectile)

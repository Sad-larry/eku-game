# ==============================================================================
#   shoot_behavior.gd
#   功能：远程射击行为。敌人以固定时间间隔向玩家发射投掷物，
#        仅在检测到玩家时激活。
# ==============================================================================
extends EnemyBehavior
class_name ShootBehavior

# ========================== 导出变量模块 ==========================
## 发射间隔（秒）
@export var fire_interval: float = 2.0

## 投掷物预制体（需是 PackedScene，根节点为 Area2D 或 RigidBody2D）
@export var projectile_scene: PackedScene

## 发射位置（相对于敌人的位置偏移，如枪口位置）
@export var muzzle_offset: Vector2 = Vector2(16, 0)

# ========================== 内部变量模块 ==========================
## 已累计的间隔计时（秒）
var _timer: float = 0.0

# ========================== 生命周期模块 ==========================
func _on_update(delta: float) -> void:
	# 只有在检测到玩家时才计时
	if not enemy.player_detected:
		_timer = 0.0
		return
	
	_timer += delta
	if _timer < fire_interval:
		return
	_timer = 0.0
	
	_shoot()

# ========================== 内部方法模块 ==========================
func _shoot() -> void:
	if projectile_scene == null:
		return
	
	# 实例化投掷物
	var projectile: Node2D = projectile_scene.instantiate()
	if projectile == null:
		return
	
	# 计算发射位置（朝向敌人面朝方向）
	var dir: float = signf(enemy.sprite.scale.x)  # -1 朝左，1 朝右
	var spawn_pos: Vector2 = enemy.global_position + Vector2(muzzle_offset.x * dir, muzzle_offset.y)
	
	projectile.global_position = spawn_pos
	# 如果有 Projectile 组件，可设置方向和速度
	if projectile.has_method("launch"):
		var target_dir: Vector2 = Vector2(dir, 0)
		if enemy.get_target():
			target_dir = (enemy.get_target().global_position - spawn_pos).normalized()
		projectile.launch(target_dir)
	
	# 挂载到场景树
	enemy.get_parent().add_child(projectile)

extends Node
class_name HealthComponent

# 角色受击、死亡、血量变化信号（外部血条/动画监听用）
signal on_unit_hit
signal on_unit_died
signal on_health_changed(current: float, max: float)

# 最大血量 & 当前血量
var max_health := 1.0
var current_health := 1.0

# 初始化：从角色属性设置最大血量，并刷新显示
func setup(stats: UnitStats) -> void:
	max_health = stats.health
	current_health = max_health
	on_health_changed.emit(current_health, max_health)

# 受到伤害：扣血、限制最低为0、触发受击/死亡逻辑
func take_damage(value: float) -> void:
	if current_health <= 0:
		return
	current_health -= value
	current_health = max(current_health, 0)
	
	on_unit_hit.emit()
	on_health_changed.emit(current_health, max_health)
	
	# 血量归0 → 触发死亡
	if current_health <= 0:
		current_health = 0
		on_unit_died.emit()
		
# 治疗逻辑：加血、限制不超过最大血量
func heal(amount: float) -> void:
	if current_health <= 0:
		return
	current_health += amount
	current_health = min(current_health, max_health)
	
	on_health_changed.emit(current_health, max_health)

# 死亡：销毁角色本体
func die() -> void:
	owner.queue_free()

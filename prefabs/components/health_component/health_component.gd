extends Node
class_name HealthComponent

# 角色受击、死亡、血量变化信号（外部血条/动画监听用）
signal unit_hit
signal unit_died
signal health_updated(new_health: int, new_max_health: int)

# 最大血量 & 当前血量
var max_health := 1
var current_health := 1

# 初始化：从角色属性设置最大血量，并刷新显示
func setup(stats: UnitStats) -> void:
	max_health = stats.max_health
	current_health = max_health
	health_updated.emit(current_health, max_health)

# 受到伤害：扣血、限制最低为0、触发受击/死亡逻辑
func take_damage(value: int) -> void:
	if current_health <= 0:
		return
	current_health -= value
	current_health = max(current_health, 0)
	
	unit_hit.emit()
	health_updated.emit(current_health, max_health)
	
	if current_health <= 0:
		current_health = 0
		unit_died.emit()
		
# 治疗逻辑：加血、限制不超过最大血量
func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health += amount
	current_health = min(current_health, max_health)
	
	health_updated.emit(current_health, max_health)

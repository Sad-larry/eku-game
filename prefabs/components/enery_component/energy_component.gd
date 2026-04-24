extends Node
class_name EneryComponent

signal on_unit_attack
signal on_unit_exhausted
signal on_energy_changed(current: int, max: int)

# 最大能量值 & 当前能量值
var max_energy := 1
var current_energy := 1

# 初始化：从角色属性设置最大血量，并刷新显示
func setup(stats: UnitStats) -> void:
	max_energy = stats.energy
	current_energy = max_energy
	on_energy_changed.emit(current_energy, max_energy)

func attack(value: int) -> void:
	if current_energy <= 0:
		return
	current_energy -= value
	current_energy = max(current_energy, 0)
	
	on_unit_attack.emit()
	on_energy_changed.emit(current_energy, max_energy)
	
	# 血量归0 → 触发死亡
	if current_energy <= 0:
		current_energy = 0
		on_unit_exhausted.emit()
		
# 死亡：销毁角色
func die() -> void:
	owner.queue_free()

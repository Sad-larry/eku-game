extends Node
class_name EnergyComponent

signal unit_attack
signal unit_exhausted
signal energy_changed(current: int, max: int)

# 最大能量值 & 当前能量值
var max_energy := 1
var current_energy := 1

# 初始化
func setup(stats: UnitStats) -> void:
	max_energy = stats.max_energy
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)

func attack(value: int) -> void:
	if current_energy <= 0:
		return
	current_energy -= value
	current_energy = max(current_energy, 0)
	
	unit_attack.emit()
	energy_changed.emit(current_energy, max_energy)
	
	if current_energy <= 0:
		current_energy = 0
		unit_exhausted.emit()
		

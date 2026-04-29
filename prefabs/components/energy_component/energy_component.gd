# ==============================================================================
#   EnergyComponent.gd
#   功能：能量组件，管理角色的能量值（如法力值、耐力值等），支持能量消耗、
#        能量耗尽信号、能量变化信号的触发。
# ==============================================================================
extends Node
class_name EnergyComponent

# ========================== 信号声明模块 ==========================
## 触发时机：角色成功消耗能量发动攻击时调用 attack() 后触发
signal unit_attack

## 触发时机：能量值耗尽（current_energy ≤ 0）时触发
signal unit_exhausted

## 触发时机：能量值发生变化时触发（包括初始化和消耗后）
## 参数：current (int) - 当前能量值，max (int) - 最大能量值
signal energy_changed(current: int, max: int)

# ========================== 变量定义模块 ==========================
## 最大能量值（上限）
var max_energy := 1

## 当前能量值
var current_energy := 1

# ========================== 公共 API 模块 ==========================
## 功能：初始化能量组件，根据 UnitStats 资源设置最大能量和当前能量
## 参数：stats (UnitStats) - 单位属性资源，需包含 max_energy 字段
func setup(stats: UnitStats) -> void:
	max_energy = stats.max_energy
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)

## 功能：消耗能量发动攻击
## 参数：value (int) - 本次攻击消耗的能量值
## 说明：若当前能量不足则不执行消耗；消耗后若能量归零则触发 unit_exhausted 信号
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

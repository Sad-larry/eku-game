# ==============================================================================
#   health_component.gd
#   功能：生命值组件，管理角色的生命值（血量），支持受到伤害、治疗、血量变化信号、
#        死亡信号，并自动处理血量边界限制（0 ~ 最大血量）。
# ==============================================================================
extends Node
class_name HealthComponent

# ========================== 信号声明模块 ==========================
## 触发时机：角色受到伤害时触发（伤害判定成功后，血量减少前/后均可，具体看实现顺序）
signal unit_hit
## 触发时机：角色死亡（current_health ≤ 0）时触发
signal unit_died
## 触发时机：血量发生变化时触发（包括初始化、受伤、治疗）
## 参数：new_health (int) - 当前生命值，new_max_health (int) - 最大生命值
signal health_updated(new_health: int, new_max_health: int)

# ========================== 变量定义模块 ==========================
## 最大生命值（上限）
var max_health: int = 1
## 当前生命值
var current_health: int = 1

# ========================== 公共 API 模块 ==========================
## 功能：初始化生命值组件，根据 UnitStats 资源设置最大生命值并重置当前生命值
## 参数：stats (UnitStats) - 单位属性资源，需包含 max_health 字段
func setup(stats: UnitStats) -> void:
	max_health = stats.max_health
	current_health = max_health
	health_updated.emit(current_health, max_health)

## 功能：受到伤害，扣除血量
## 参数：value (int) - 本次受到的伤害值（正数）
## 说明：若当前生命值已 ≤ 0 则忽略本次伤害；扣血后若生命值归零则触发 unit_died 信号
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

## 功能：治疗，回复血量
## 参数：amount (int) - 本次治疗量（正数）
## 说明：若当前生命值已 ≤ 0 则忽略治疗；治疗后生命值不超过最大生命值
func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health += amount
	current_health = min(current_health, max_health)
	health_updated.emit(current_health, max_health)

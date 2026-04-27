extends Resource
class_name UnitStats

enum UnitType {
	PLAYER,
	ENEMY
}

## 实体名字
@export var name: String
## 实体所属类型：玩家/敌人
@export var type: UnitType
## 实体图标
@export var icon: Texture2D
## 实体速度
@export var speed := 100
## 实体生命值
@export var max_health := 1
## 实体能量值
@export var max_energy := 1
## 实体每秒回能
@export var energy_regen: float = 1
## 实体伤害值
@export var base_attack_damage := 1
## 实体攻速
@export var attack_speed: float = 1.0
## 实体暴击率
@export var crit_rate: float = 0.05
## 实体暴击伤害
@export var crit_damage: float = 1.5

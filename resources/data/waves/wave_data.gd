# ==============================================================================
#   wave_data.gd
#   功能：波次数据资源类，定义房间内一波敌人的生成配置，包括生成数量范围、
#        生成时间间隔、敌方单位池及权重等，支持固定和随机生成两种模式。
# ==============================================================================
extends Resource
class_name WaveData

# ========================== 枚举定义模块 ==========================
## 生成类型枚举
enum SpawnType {
	FIXED,   ## 固定时间间隔生成
	RANDOM   ## 随机时间间隔生成
}

# ========================== 导出变量模块 ==========================
# ----- 波次调度属性 -----
## 波次起始索引（用于波次顺序控制）
@export var from: int
## 波次结束索引（用于波次顺序控制）
@export var to: int
## 波次持续时间（秒），超过此时间后未生成的敌人可能被跳过或进入下一波
@export var wave_time := 20.0
## 敌方单位配置列表（包含场景和权重）
@export var units: Array[WaveUnitData]
# ----- 生成时间配置 -----
## 生成类型（固定间隔/随机间隔）
@export var spawn_type := SpawnType.RANDOM
## 固定生成间隔（秒，当 spawn_type == FIXED 时生效）
@export var fixed_spawn_time := 1.0
## 最小随机生成间隔（秒，当 spawn_type == RANDOM 时生效）
@export var min_spawn_time := 1.0
## 最大随机生成间隔（秒，当 spawn_type == RANDOM 时生效）
@export var max_spawn_time := 1.0
# ----- 生成数量配置 -----
## 本波次最小生成敌人数
@export var spawn_count_min: int = 3
## 本波次最大生成敌人数
@export var spawn_count_max: int = 6

# ========================== 公共方法模块 ==========================
## 功能：根据权重随机获取一个敌方单位场景
## 返回值：PackedScene - 敌方单位场景资源，若单位列表为空则返回 null
func get_random_unit_scene() -> PackedScene:
	if units.is_empty():
		printerr("No Units")
		return null
	
	var enemies: Array[PackedScene]
	var weights: Array[float]
	
	for i in units.size():
		enemies.append(units[i].unit_scene)
		weights.append(units[i].weight)
	
	var rng := RandomNumberGenerator.new()
	var random_unit = enemies[rng.rand_weighted(weights)]
	return random_unit

## 功能：判断指定索引是否在波次的有效索引范围内
## 参数：index (int) - 要检查的索引值
## 返回值：bool - true 表示索引在 [from, to] 范围内
func is_valid_index(index: int) -> bool:
	return index >= from and index <= to

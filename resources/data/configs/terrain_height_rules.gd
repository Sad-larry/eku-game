# ==============================================================================
#   terrain_height_rules.gd
#   功能：定义高度区间到地形类型的映射规则（10 种地形）。
#         以 Resource 形式存在，可在编辑器中创建 .tres 文件并配置各阈值。
#   用法：创建 .tres 资源，调整高度阈值，然后传入 TerrainGenerator。
# ==============================================================================
extends Resource
class_name TerrainHeightRules

# ========================== 地形类型枚举 ==========================
## 地形类型（按高度从低到高排列）
enum TerrainType {
	DEEP_WATER   = 0,  # 深水
	SHALLOW_WATER= 1,  # 浅水
	SAND         = 2,  # 沙地
	MUD          = 3,  # 泥地
	GRASS        = 4,  # 草地
	FLOWER       = 5,  # 花地
	STONE        = 6,  # 石地
	MOUNTAIN     = 7,  # 山地
	ROCK         = 8,  # 岩石
	SNOW         = 9,  # 雪地
}

# ========================== 导出属性模块 ==========================
## 深水上界 [-1.0, deep_water_upper) → DEEP_WATER
@export var deep_water_upper: float = -0.6

## 浅水上界 [deep_water_upper, shallow_water_upper) → SHALLOW_WATER
@export var shallow_water_upper: float = -0.3

## 沙地上界 [shallow_water_upper, sand_upper) → SAND
@export var sand_upper: float = -0.15

## 泥地上界 [sand_upper, mud_upper) → MUD
@export var mud_upper: float = -0.1

## 草地上界 [mud_upper, grass_upper) → GRASS
@export var grass_upper: float = 0.2

## 花地上界 [grass_upper, flower_upper) → FLOWER
@export var flower_upper: float = 0.75

## 石地上界 [flower_upper, stone_upper) → STONE
@export var stone_upper: float = 0.8

## 山地上界 [stone_upper, mountain_upper) → MOUNTAIN
@export var mountain_upper: float = 0.83

## 岩石上界 [mountain_upper, rock_upper) → ROCK
@export var rock_upper: float = 0.85

## 雪地 [rock_upper, 1.0] → SNOW

## 地形名称（按枚举顺序，仅用于显示/调试）
@export var terrain_names: Array[String] = [
	"深水", "浅水", "沙地", "泥地", "草地",
	"花地", "石地", "山地", "岩石", "雪地",
]

# ========================== 公共 API 模块 ==========================
## 根据高度值返回对应的地形类型枚举值
func get_terrain_type(height: float) -> int:
	var clamped := clampf(height, -1.0, 1.0)

	if clamped < deep_water_upper:
		return TerrainType.DEEP_WATER
	elif clamped < shallow_water_upper:
		return TerrainType.SHALLOW_WATER
	elif clamped < sand_upper:
		return TerrainType.SAND
	elif clamped < mud_upper:
		return TerrainType.MUD
	elif clamped < grass_upper:
		return TerrainType.GRASS
	elif clamped < flower_upper:
		return TerrainType.FLOWER
	elif clamped < stone_upper:
		return TerrainType.STONE
	elif clamped < mountain_upper:
		return TerrainType.MOUNTAIN
	elif clamped < rock_upper:
		return TerrainType.ROCK
	else:
		return TerrainType.SNOW

## 计算高度值在其所属地形区间内的偏移量，用于过渡带混合。
## 返回值范围 [0.0, 1.0]：
##   - 0.0 = 位于区间正中心（地形纯粹，无需混合）
##   - 1.0 = 位于区间边界（需要过渡混合）
func get_blend_weight(height: float) -> float:
	var clamped := clampf(height, -1.0, 1.0)

	for i in _get_interval_count():
		var min_h := _get_interval_min(i)
		var max_h := _get_interval_max(i)
		if clamped >= min_h and clamped < max_h:
			var mid := (min_h + max_h) * 0.5
			var half := (max_h - min_h) * 0.5
			if half <= 0.0:
				return 0.0
			return clampf(abs(clamped - mid) / half, 0.0, 1.0)

	return 0.0

## 获取地形类型的可读名称
func get_terrain_name(terrain_type: int) -> String:
	if terrain_type >= 0 and terrain_type < terrain_names.size():
		return terrain_names[terrain_type]
	return "未知"

# ========================== 工具方法模块 ==========================

## 返回 10 个高度区间
func _get_interval_count() -> int:
	return 10

## 获取指定区间索引的下界
func _get_interval_min(index: int) -> float:
	match index:
		0: return -1.0
		1: return deep_water_upper
		2: return shallow_water_upper
		3: return sand_upper
		4: return mud_upper
		5: return grass_upper
		6: return flower_upper
		7: return stone_upper
		8: return mountain_upper
		9: return rock_upper
		_: return -1.0

## 获取指定区间索引的上界
func _get_interval_max(index: int) -> float:
	match index:
		0: return deep_water_upper
		1: return shallow_water_upper
		2: return sand_upper
		3: return mud_upper
		4: return grass_upper
		5: return flower_upper
		6: return stone_upper
		7: return mountain_upper
		8: return rock_upper
		9: return 1.0
		_: return 1.0

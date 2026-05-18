# ==============================================================================
#   layer_progression_config.gd
#   功能：层级进度总配置，包含所有层级的配置列表和难度曲线。
#        作为全局配置资源，由 RunManager 和 GameWorld 查询使用。
# ==============================================================================
extends Resource
class_name LayerProgressionConfig

# ========================== 导出变量模块 ==========================
## 所有层级的配置列表（索引 0 = 第 1 层）
@export var layers: Array[Resource] = []

## 难度曲线（X = 层索引归一化值，Y = 综合难度系数）
## 为空时使用默认公式：1 + 0.15 * (layer - 1)
@export var difficulty_curve: Curve = null

## 默认最大环数（当层配置未指定时使用）
@export var default_max_ring: int = 4

# ========================== 公共 API 模块 ==========================
## 功能：获取指定层的配置
## 参数：layer (int) - 层索引（从 1 开始）
## 返回值：LayerConfig - 层配置，超出范围时返回 null
func get_config_for_layer(layer: int) -> LayerConfig:
	var index := layer - 1
	if index >= 0 and index < layers.size():
		return layers[index] as LayerConfig
	return null

## 功能：获取指定层的最大环数
## 参数：layer (int) - 层索引
## 返回值：int - 最大环数
func get_max_ring(layer: int) -> int:
	var config := get_config_for_layer(layer)
	if config:
		return config.max_ring
	return default_max_ring

## 功能：获取指定层的综合难度系数
## 参数：layer (int) - 层索引
## 返回值：float - 难度系数（1.0 = 基础难度）
func get_difficulty_coefficient(layer: int) -> float:
	if difficulty_curve:
		# 将层索引归一化到曲线的 X 范围
		var max_layer := max(layers.size(), 1)
		var t := float(layer - 1) / float(max_layer)
		return difficulty_curve.sample(clampf(t, 0.0, 1.0))
	# 默认公式：每层增加 15% 难度
	return 1.0 + 0.15 * (layer - 1)

## 功能：获取指定层的敌人血量倍率
## 参数：layer (int) - 层索引
## 返回值：float - 血量倍率
func get_enemy_health_multiplier(layer: int) -> float:
	var config := get_config_for_layer(layer)
	if config:
		return config.enemy_health_multiplier * get_difficulty_coefficient(layer)
	return get_difficulty_coefficient(layer)

## 功能：获取指定层的敌人伤害倍率
## 参数：layer (int) - 层索引
## 返回值：float - 伤害倍率
func get_enemy_damage_multiplier(layer: int) -> float:
	var config := get_config_for_layer(layer)
	if config:
		return config.enemy_damage_multiplier * get_difficulty_coefficient(layer)
	return get_difficulty_coefficient(layer)

## 功能：获取指定层的金币倍率
## 参数：layer (int) - 层索引
## 返回值：float - 金币倍率
func get_coin_multiplier(layer: int) -> float:
	var config := get_config_for_layer(layer)
	if config:
		return config.coin_multiplier
	return 1.0

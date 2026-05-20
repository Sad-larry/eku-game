# ==============================================================================
#   difficulty_table.gd
#   功能：难度表资源，定义ring值与敌人强度/数量/奖励的数值映射。
#        由 RunManager 查询，应用到敌人生成和奖励计算。
# ==============================================================================
extends Resource
class_name DifficultyTable

# ========================== Ring 缩放配置 ==========================
## Ring 缩放映射表 {ring: {hp, dmg, count, coin, elite}}
## ring 从 0 开始（中心），向外递增
@export var ring_scaling: Dictionary = {
	0: {"hp": 1.0, "dmg": 1.0, "count": 1.0, "coin": 1.0, "elite": 0.0},
	1: {"hp": 1.0, "dmg": 1.0, "count": 1.0, "coin": 1.0, "elite": 0.0},
	2: {"hp": 1.2, "dmg": 1.1, "count": 1.2, "coin": 1.2, "elite": 0.05},
	3: {"hp": 1.5, "dmg": 1.3, "count": 1.5, "coin": 1.5, "elite": 0.1},
	4: {"hp": 1.8, "dmg": 1.5, "count": 1.8, "coin": 1.8, "elite": 0.15},
	5: {"hp": 2.2, "dmg": 1.8, "count": 2.0, "coin": 2.2, "elite": 0.2},
}

# ========================== Layer 缩放配置 ==========================
## Layer 全局倍率 {layer: multiplier}
@export var layer_scaling: Dictionary = {
	1: 1.0,
	2: 1.3,
	3: 1.6,
	4: 2.0,
	5: 2.5,
}

# ========================== BOSS 缩放配置 ==========================
## BOSS 属性倍率 {layer: multiplier}
@export var boss_scaling: Dictionary = {
	1: 1.0,
	2: 1.5,
	3: 2.0,
	4: 2.8,
	5: 3.5,
}

# ========================== 查询 API ==========================
## 功能：获取指定 ring 的敌人血量倍率
## 参数：ring (int) - ring 值；layer (int) - 层值
## 返回值：float - 血量倍率
func get_enemy_hp_multiplier(ring: int, layer: int = 1) -> float:
	var ring_data: Dictionary = _get_ring_data(ring)
	var layer_mult: float = layer_scaling.get(layer, 1.0)
	return ring_data.get("hp", 1.0) * layer_mult

## 功能：获取指定 ring 的敌人伤害倍率
## 参数：ring (int) - ring 值；layer (int) - 层值
## 返回值：float - 伤害倍率
func get_enemy_dmg_multiplier(ring: int, layer: int = 1) -> float:
	var ring_data: Dictionary = _get_ring_data(ring)
	var layer_mult: float = layer_scaling.get(layer, 1.0)
	return ring_data.get("dmg", 1.0) * layer_mult

## 功能：获取指定 ring 的敌人数量倍率
## 参数：ring (int) - ring 值
## 返回值：float - 数量倍率
func get_enemy_count_multiplier(ring: int) -> float:
	var ring_data: Dictionary = _get_ring_data(ring)
	return ring_data.get("count", 1.0)

## 功能：获取指定 ring 的金币倍率
## 参数：ring (int) - ring 值；layer (int) - 层值
## 返回值：float - 金币倍率
func get_coin_multiplier(ring: int, layer: int = 1) -> float:
	var ring_data: Dictionary = _get_ring_data(ring)
	var layer_mult: float = layer_scaling.get(layer, 1.0)
	return ring_data.get("coin", 1.0) * layer_mult

## 功能：获取指定 ring 的精英出现概率
## 参数：ring (int) - ring 值
## 返回值：float - 精英概率（0.0-1.0）
func get_elite_chance(ring: int) -> float:
	var ring_data: Dictionary = _get_ring_data(ring)
	return ring_data.get("elite", 0.0)

## 功能：获取指定 layer 的 BOSS 属性倍率
## 参数：layer (int) - 层值
## 返回值：float - BOSS 倍率
func get_boss_multiplier(layer: int) -> float:
	return boss_scaling.get(layer, 1.0)

## 功能：获取指定 ring 的完整缩放数据
## 参数：ring (int) - ring 值；layer (int) - 层值
## 返回值：Dictionary - 包含所有缩放值的字典
func get_full_scaling(ring: int, layer: int = 1) -> Dictionary:
	return {
		"hp": get_enemy_hp_multiplier(ring, layer),
		"dmg": get_enemy_dmg_multiplier(ring, layer),
		"count": get_enemy_count_multiplier(ring),
		"coin": get_coin_multiplier(ring, layer),
		"elite": get_elite_chance(ring),
		"boss": get_boss_multiplier(layer)
	}

# ========================== 内部方法 ==========================
## 功能：获取 ring 缩放数据，超出范围时使用最大 ring 的数据
func _get_ring_data(ring: int) -> Dictionary:
	if ring_scaling.has(ring):
		return ring_scaling[ring]
	# 超出配置范围时，使用最大 ring 的数据并额外缩放
	var max_ring: int = 0
	for key in ring_scaling:
		if key is int and key > max_ring:
			max_ring = key
	if max_ring > 0:
		var max_data: Dictionary = ring_scaling[max_ring]
		var extra: float = ring - max_ring
		return {
			"hp": max_data.get("hp", 1.0) * (1.0 + extra * 0.3),
			"dmg": max_data.get("dmg", 1.0) * (1.0 + extra * 0.2),
			"count": max_data.get("count", 1.0) * (1.0 + extra * 0.15),
			"coin": max_data.get("coin", 1.0) * (1.0 + extra * 0.25),
			"elite": minf(max_data.get("elite", 0.0) + extra * 0.05, 0.5)
		}
	return {"hp": 1.0, "dmg": 1.0, "count": 1.0, "coin": 1.0, "elite": 0.0}

# ==============================================================================
#   relic_pool.gd
#   功能：遗物掉落池资源。管理遗物的随机选取。
# ==============================================================================
class_name RelicPool extends Resource

@export var relics: Array[RelicData] = []

## 功能：随机选取指定数量的遗物
func roll_relics(count: int) -> Array[RelicData]:
	if relics.is_empty():
		return []
	var pool := relics.duplicate()
	var result: Array[RelicData] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in mini(count, pool.size()):
		var idx := rng.randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result

## 功能：按稀有度过滤
func get_by_rarity(rarity: RelicData.Rarity) -> Array[RelicData]:
	var result: Array[RelicData] = []
	for relic in relics:
		if relic.rarity == rarity:
			result.append(relic)
	return result

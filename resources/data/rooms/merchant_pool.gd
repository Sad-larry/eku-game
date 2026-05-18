# ==============================================================================
#   merchant_pool.gd
#   功能：商人商品池资源。定义可出售的商品列表。
# ==============================================================================
class_name MerchantPool extends Resource

## 商品类型枚举
enum ItemType { HEAL, ENERGY, BUFF, RELIC }

## 单个商品定义
class MerchantItem extends RefCounted:
	var item_type: ItemType
	var display_name: String
	var description: String
	var base_price: int
	var effect_value: int  # 回复量/buff 强度等

	func _init(p_type: ItemType, p_name: String, p_desc: String, p_price: int, p_value: int = 0) -> void:
		item_type = p_type
		display_name = p_name
		description = p_desc
		base_price = p_price
		effect_value = p_value

## 商品条目列表
@export var items: Array[Dictionary] = []

## 功能：根据 ring 和 layer 计算最终价格
func calculate_price(base_price: int, ring: int, layer: int) -> int:
	return int(base_price * pow(1.1, ring) * pow(1.2, layer))

## 功能：随机选取指定数量的商品
func roll_items(count: int, ring: int, layer: int) -> Array[MerchantItem]:
	var pool := _build_pool()
	if pool.is_empty():
		return []
	var result: Array[MerchantItem] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in mini(count, pool.size()):
		var idx := rng.randi() % pool.size()
		var item: MerchantItem = pool[idx]
		# 重新计算价格
		var final_item := MerchantItem.new(
			item.item_type, item.display_name, item.description,
			calculate_price(item.base_price, ring, layer), item.effect_value
		)
		result.append(final_item)
		pool.remove_at(idx)
	return result

func _build_pool() -> Array[MerchantItem]:
	var pool: Array[MerchantItem] = [
		MerchantItem.new(ItemType.HEAL, "生命药水", "回复 30% 生命值", 15, 30),
		MerchantItem.new(ItemType.HEAL, "高级生命药水", "回复 60% 生命值", 35, 60),
		MerchantItem.new(ItemType.ENERGY, "能量药剂", "回复 50 点能量", 10, 50),
		MerchantItem.new(ItemType.BUFF, "力量卷轴", "伤害 +20%（本层）", 25, 20),
		MerchantItem.new(ItemType.BUFF, "敏捷药水", "移速 +25%（本层）", 20, 25),
	]
	return pool

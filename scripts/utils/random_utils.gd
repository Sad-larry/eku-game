# ==============================================================================
#   random_utils.gd
#   功能：概率与随机工具类，提供概率判定、加权随机选择等通用方法。
#         纯静态工具，不依赖任何全局状态。
# ==============================================================================
extends RefCounted
class_name RandomUtils

## 功能：概率判定函数
## 参数：probability (float) - 目标概率，范围 0.0 - 1.0
## 返回值：bool - true 表示命中（概率成功），false 表示未命中
## 示例：get_chance_success(0.75) 返回 true 的概率为 75%
static func get_chance_success(probability: float) -> bool:
	return randf() < probability

## 功能：在数组中按权重随机选择一个元素
## 参数：items (Array) - 待选择的元素数组；weights (Array[float]) - 对应的权重数组
## 返回值：混合类型 - 随机选中的元素，若参数无效则返回 null
## 说明：weights 数组长度必须与 items 数组长度一致；总权重为各权重之和
## 示例：weighted_random(["铁剑", "木盾", "药水"], [10.0, 5.0, 3.0])
static func weighted_random(items: Array, weights: Array[float]):
	if items.is_empty() or weights.is_empty():
		return null
	if items.size() != weights.size():
		push_error("RandomUtils.weighted_random: items 和 weights 长度不一致")
		return null

	var total: float = 0.0
	for w in weights:
		total += w

	# 所有权重为 0 时退化为均匀随机
	if total <= 0.0:
		return items[randi() % items.size()]

	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in items.size():
		cumulative += weights[i]
		if roll < cumulative:
			return items[i]

	return items[-1]

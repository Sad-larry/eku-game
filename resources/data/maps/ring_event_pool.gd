# ==============================================================================
#   ring_event_pool.gd
#   功能：指定某个难度圈层的事件权重分布
#         用于按圈层配置不同的事件出现概率，支持权重随机抽取
# ==============================================================================
extends Resource
class_name RingEventPool

# ========================== 导出变量模块 ==========================
## 所属圈层索引（0 表示中心起始圈，1~N 为外层）
@export var ring_index: int

## 事件类型 → 权重映射（权重越高出现概率越大）
## 支持的键：battle, elite, merchant, treasure, rest, random, trap, npc
@export var weights: Dictionary = {
	"battle": 70,
	"elite": 30,
	"merchant": 20,
	"treasure": 15,
	"rest": 10,
	"random": 5,
	"trap": 5,
	"npc": 5,
}

# ========================== 公共 API 模块 ==========================
## 功能：从本池中按权重随机选择一个事件类型
## 参数：rng (RandomNumberGenerator) - 随机数生成器实例，需已设置种子
## 返回值：String - 选中的事件类型标识（如 "battle", "elite" 等）
func pick_event(rng: RandomNumberGenerator) -> String:
	# 收集所有权重大于 0 的事件类型及对应权重
	var types: Array[String] = []
	var vals: Array[float] = []
	for event_type in weights:
		var w: float = weights[event_type]
		if w > 0.0:
			types.append(event_type)
			vals.append(w)

	# 若无有效权重，默认返回战斗事件
	if types.is_empty():
		return "battle"

	# 计算权重总和
	var total: float = 0.0
	for v in vals:
		total += v

	# 随机滚动并确定选中项
	var roll: float = rng.randf() * total
	var cumulative: float = 0.0
	for i in types.size():
		cumulative += vals[i]
		if roll < cumulative:
			return types[i]

	# 保底返回最后一个类型（理论上不会执行到此）
	return types[-1]

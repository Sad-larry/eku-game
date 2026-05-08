# ==============================================================================
#   IsoSorting.gd
#   功能：等距场景排序控制器，每帧根据子节点的 Y 轴坐标（全局）重新排序，
#        以正确解决等距视角下的遮挡关系（Y 值越小越靠上，越先绘制）。
# ==============================================================================
extends Node
class_name IsoSorting

@export var sort_groups: Array[Node2D] = []

# ========================== 生命周期模块 ==========================
## 功能：每帧执行子节点排序逻辑
## 参数：_delta (float) - 帧间隔时间（未使用）
## 说明：将当前节点的所有子节点按全局 Y 坐标从小到大排序，并重新调整树中的绘制顺序。
##       排序依据的公式：等距透视中，Y 坐标越小（越靠近屏幕上方）的物体应越先绘制。
func _process(_delta: float) -> void:
	# 收集所有分组中需要排序的 CanvasItem 节点
	var items: Array[Node2D] = []
	for group in sort_groups:
		_collect_sortable(group, items)
	
	 # 按 Y 坐标降序排列（Y越大越靠前）
	items.sort_custom(_compare_y)
	
	# 分配 z_index，确保按序绘制
	for i in items.size():
		items[i].z_index = i

## 功能：递归单层收集目标节点下所有可视画布子节点
func _collect_sortable(node: Node2D, output: Array[Node2D]) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			output.append(child)

## 功能：将当前节点的所有子节点按全局 Y 坐标从小到大排序
static func _compare_y(a: Node2D, b: Node2D) -> bool:
	return a.global_position.y < b.global_position.y

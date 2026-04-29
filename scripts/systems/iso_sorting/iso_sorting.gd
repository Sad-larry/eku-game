# ==============================================================================
#   IsoSorting.gd
#   功能：等距场景排序控制器，每帧根据子节点的 Y 轴坐标（全局）重新排序，
#        以正确解决等距视角下的遮挡关系（Y 值越小越靠上，越先绘制）。
# ==============================================================================
extends Node
class_name IsoSorting

# ========================== 生命周期模块 ==========================
## 功能：每帧执行子节点排序逻辑
## 参数：_delta (float) - 帧间隔时间（未使用）
## 说明：将当前节点的所有子节点按全局 Y 坐标从小到大排序，并重新调整树中的绘制顺序。
##       排序依据的公式：等距透视中，Y 坐标越小（越靠近屏幕上方）的物体应越先绘制。
func _process(_delta: float) -> void:
	var children: Array[Node] = get_children()
	
	# 按全局 Y 坐标升序排序（Y 值小的在前，作为底层先绘制）
	children.sort_custom(func(a, b): 
		return (a as Node2D).global_position.y < (b as Node2D).global_position.y
	)
	
	# 按排序后的顺序移动子节点（改变绘制顺序）
	for i in children.size():
		move_child(children[i], i)

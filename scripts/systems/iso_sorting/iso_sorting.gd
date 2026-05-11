# ==============================================================================
#   IsoSorting.gd
#   功能：等距场景排序控制器，每帧根据子节点的 Y 轴坐标（全局）重新排序，
#        以正确解决等距视角下的遮挡关系（Y 值越小越靠上，越先绘制）。
# ==============================================================================
extends Node
class_name IsoSorting

@export var sort_groups: Array[Node2D] = []

## 排序起始 z_index 偏移量。所有参与排序的节点将分配从该值开始的 z_index。
## 场景中有 Tilemap 等不参与排序的底层节点时（z_index=0），将此值设为 1，
## 可确保所有排序节点绘制在底层之上，避免 Sprite2D 被 Tilemap 遮挡。
@export var sort_base_z_index: int = 1

## 加入此 Group 的节点（或其祖先）将不参与 Y 排序，整棵子树被跳过。
## 用法：在场景编辑器中选中不想排序的节点（如 Portal 的 Area2D），
##       在 Node 属性面板的 "Groups" 中添加此标签即可。
const IGNORE_GROUP: StringName = &"iso_sort_ignore"

# ========================== 生命周期模块 ==========================
## 功能：每帧执行子节点排序逻辑
## 说明：将 sort_groups 中收集到的所有 Sprite2D/AnimatedSprite2D 叶子节点
##       按全局 Y 坐标排序，并分配从 sort_base_z_index 开始的 z_index。
func _process(_delta: float) -> void:
	var items: Array[Node2D] = []
	for group in sort_groups:
		_collect_sortable(group, items)

	items.sort_custom(_compare_y)

	for i in items.size():
		items[i].z_index = sort_base_z_index + i

## 功能：递归收集目标节点下所有需要排序的视觉叶子节点
## 说明：仅收集 Sprite2D 和 AnimatedSprite2D 类型的节点，跳过纯容器 Node2D。
##       对于包含视觉子节点的容器节点，递归进入其内部继续查找。
##       这样可以正确处理 Cabin > Furniture > Bed 等多层嵌套结构，
##       同时避免将无视觉的容器节点加入排序数组。
func _collect_sortable(node: Node2D, output: Array[Node2D]) -> void:
	for child in node.get_children():
		# 跳过标记为"不参与排序"的节点及其整棵子树
		if child.is_in_group(IGNORE_GROUP):
			continue
		if child is Sprite2D or child is AnimatedSprite2D:
			output.append(child)
		elif child is Node2D and _has_visual_descendant(child):
			_collect_sortable(child, output)

## 功能：递归判断节点是否包含视觉类后代节点（Sprite2D / AnimatedSprite2D）
## 返回：true 表示该节点内部含有需要排序的视觉节点，需要递归遍历
static func _has_visual_descendant(node: Node2D) -> bool:
	for child in node.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return true
		if child is Node2D and _has_visual_descendant(child):
			return true
	return false

## 功能：按全局 Y 坐标比较两个节点的绘制顺序
static func _compare_y(a: Node2D, b: Node2D) -> bool:
	return a.global_position.y < b.global_position.y

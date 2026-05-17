# ==============================================================================
#   iso_sorting.gd
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

# ========================== 缓存与脏标记 ==========================
var _cached_items: Array[Node2D] = []
# 当场景子节点发生增删时标记为脏，下次排序时重建列表
var _dirty: bool = true

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	# 监听子节点的增删，以便自动标记脏数据
	child_entered_tree.connect(_on_child_structure_changed)
	child_exiting_tree.connect(_on_child_structure_changed)

## 功能：每帧执行子节点排序逻辑
## 说明：将 sort_groups 中收集到的所有 Sprite2D/AnimatedSprite2D/CanvasGroup
##       叶子节点按全局 Y 坐标排序，并分配从 sort_base_z_index 开始的 z_index。
##       CanvasGroup 被视为一个整体排序单元（内部子 Sprite 的层级由 CanvasGroup
##       自行管理），不递归进入其内部拆分排序。
func _process(_delta: float) -> void:
	# 仅在脏标记为 true 时才重新收集排序对象
	if _dirty:
		_rebuild_cache()
		_dirty = false

	# 基于缓存列表进行排序
	var items: Array[Node2D] = _cached_items.duplicate()
	items.sort_custom(_compare_y)

	# 分配 z_index
	for i in items.size():
		items[i].z_index = sort_base_z_index + i

# ========================== 缓存重建 ==========================
## 递归收集所有需要排序的视觉叶子节点，并缓存起来。
## 注意：CanvasGroup 节点被视为单个排序单元，其内部子 Sprite 的排序由
##       CanvasGroup 自身管理，IsoSorting 不递归进入。
func _rebuild_cache() -> void:
	_cached_items.clear()
	for group in sort_groups:
		_collect_sortable(group, _cached_items)

## 功能：递归收集目标节点下所有需要排序的视觉叶子节点
## 说明：收集 Sprite2D、AnimatedSprite2D 以及 CanvasGroup 节点。
##       CanvasGroup 被作为整体排序单元加入（不递归进入内部），
##       因为 CanvasGroup 内部子 Sprite 的 z_index 由其自行管理。
##       对于纯容器 Node2D，递归进入其内部继续查找。
func _collect_sortable(node: Node2D, output: Array[Node2D]) -> void:
	for child in node.get_children():
		# 跳过标记为"不参与排序"的节点及其整棵子树
		if child.is_in_group(IGNORE_GROUP):
			continue
		# CanvasGroup 是合成单元：将其整体加入排序，不递归进入内部。
		# 内部子 Sprite 的 z_index 由 CanvasGroup 和其子节点自身的 z_index
		# 联合管理，IsoSorting 只控制 CanvasGroup 本身的 z_index。
		if child is CanvasGroup:
			if _has_visual_descendant(child):
				output.append(child)
		elif child is Sprite2D or child is AnimatedSprite2D:
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

# ========================== 比较函数（稳定排序） ==========================
## 功能：按实体根部（父物理体）的 Y 坐标比较两个节点的绘制顺序
## 说明：sprite.global_position.y - sprite.position.y = parent.global_position.y，
##       即物理体（实体地面接触点）的 Y 坐标。这解决了精灵 position 偏移
##       导致的排序键偏低问题（如玩家 Sprite2D 的 position=(0,-14)）。
static func _compare_y(a: Node2D, b: Node2D) -> bool:
	# 按父节点（物理体/根节点）的 Y 坐标排序，解决精灵自身偏移问题
	var y_a = a.global_position.y - a.position.y
	var y_b = b.global_position.y - b.position.y
	if y_a == y_b:
		# 次级比较：使用 instance_id 保证稳定，避免画面闪烁
		return a.get_instance_id() < b.get_instance_id()
	return y_a < y_b

# ========================== 脏标记触发器 ==========================
func _on_child_structure_changed(node: Node) -> void:
	# 任何子节点的增删都可能改变排序集合，标记需要重建。
	# 这里做了一个简单判断：只关心 Node2D 类型的变动，避免无意义标记。
	if node is Node2D:
		_dirty = true

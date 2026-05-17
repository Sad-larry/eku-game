# ==============================================================================
#   visual_ysort.gd
#   功能：挂载在 YSort 容器节点上，自动收集并克隆需要 Y 排序的视觉元素
# ==============================================================================
extends Node2D

# ========================== 可调节参数 ==========================
## 用于标记需要提取视觉的节点组名（支持 StaticBody2D 和 Area2D）
@export var target_group: String = "extract_visual"

## 视觉节点的默认名称（在物理体下寻找的第一优先级名称）
@export var visual_node_name: String = "Sprite2D"

## 是否隐藏原始视觉节点（建议 true，避免重复显示）
@export var hide_original: bool = true

## 支持的视觉节点类型（可根据需要扩展）
var supported_types: Array[String] = ["Sprite2D", "AnimatedSprite2D"]

# ========================== 生命周期 ==========================
func _ready():
	# 等待一帧，确保所有子场景完成初始化
	call_deferred("_collect_and_extract")

# ========================== 主要逻辑 ==========================
## 从当前场景根节点开始递归收集并提取视觉节点
func _collect_and_extract():
	var root = get_tree().current_scene
	if not root:
		push_error("VisualYSort: 无法获取当前场景根节点")
		return
	
	var bodies: Array[Node2D] = []
	_collect_bodies(root, bodies)
	
	for body in bodies:
		_extract_visual(body)

## 递归收集所有带有目标分组的 StaticBody2D 或 Area2D
func _collect_bodies(node: Node, out_bodies: Array[Node2D]):
	for child in node.get_children():
		if (child is StaticBody2D or child is Area2D) and child.is_in_group(target_group):
			out_bodies.append(child)
		# 递归继续查找（包括非物理体的容器）
		_collect_bodies(child, out_bodies)

## 从物理体节点中提取视觉节点（克隆）并添加到当前 YSort 容器
func _extract_visual(body: Node2D):
	# 查找视觉节点：优先使用指定名称，否则查找第一个支持的节点类型
	var original: Node = null
	if visual_node_name != "" and body.has_node(visual_node_name):
		original = body.get_node(visual_node_name)
	else:
		original = _find_first_supported_visual(body)
		print(original)
	
	if not original:
		# 未找到符合要求的视觉节点，跳过
		return
	
	# 克隆视觉节点（深拷贝主要属性）
	var clone = _clone_visual(original)
	if not clone:
		return
	
	# 添加到 YSort 容器
	add_child(clone)
	clone.name = body.name + "_Visual"
	
	# 计算克隆的全局位置 = 物理体全局位置 + 原始节点相对物理体的偏移
	var offset = original.global_position - body.global_position
	clone.global_position = body.global_position + offset
	
	# 处理动画状态（如果是 AnimatedSprite2D）
	if original is AnimatedSprite2D:
		var anim_orig = original as AnimatedSprite2D
		var anim_clone = clone as AnimatedSprite2D
		anim_clone.animation = anim_orig.animation
		anim_clone.frame = anim_orig.frame
	
	# 隐藏原始视觉节点
	if hide_original:
		original.visible = false
	
## 遍历物理体节点的子节点，返回第一个类型匹配的节点
func _find_first_supported_visual(body: Node2D) -> Node:
	for child in body.get_children():
		for supported_type in supported_types:
			if child.is_class(supported_type):
				return child
	return null

## 根据原始节点类型创建克隆节点，复制通用属性
func _clone_visual(original: Node) -> Node:
	var clone: Node = null
	
	if original is Sprite2D:
		var src = original as Sprite2D
		var dst = Sprite2D.new()
		dst.texture = src.texture
		dst.centered = src.centered
		dst.offset = src.offset
		dst.scale = src.scale
		dst.modulate = src.modulate
		dst.self_modulate = src.self_modulate
		dst.flip_h = src.flip_h
		dst.flip_v = src.flip_v
		clone = dst
		
	elif original is AnimatedSprite2D:
		var src = original as AnimatedSprite2D
		var dst = AnimatedSprite2D.new()
		dst.sprite_frames = src.sprite_frames
		dst.animation = src.animation
		dst.frame = src.frame
		dst.speed_scale = src.speed_scale
		dst.offset = src.offset
		dst.scale = src.scale
		dst.modulate = src.modulate
		clone = dst
	
	# 可继续添加其他类型（如 Sprite3D 等）
	
	if clone:
		# 复制通用 CanvasItem 属性
		clone.rotation = original.rotation
		clone.z_index = original.z_index
		clone.material = original.material if original is CanvasItem else null
	
	return clone

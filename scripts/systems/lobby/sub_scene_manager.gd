# ==============================================================================
#   sub_scene_manager.gd
#   功能：子场景管理器，启动时自动扫描 ChildScenes 节点下的所有子场景，
#        提供场景激活/休眠控制、按 ID 或路径查询、PortalZone 自动注册，
#        并为 PiP 渲染提供临时场景暴露/隐藏能力。
#   挂载位置：作为 LobbyWorld 的子节点。
# ==============================================================================
extends Node
class_name SubSceneManager


# ========================== 信号声明模块 ==========================
## 场景被激活为当前场景
signal scene_activated(scene_id: String)

## 场景被休眠
signal scene_deactivated(scene_id: String)

## 新场景注册完成
signal scene_registered(scene_id: String, scene_path: String)


# ========================== 导出变量模块 ==========================
## 子场景容器节点的相对路径（默认是 LobbyWorld 下的 ChildScenes）
@export var child_scenes_node_path: NodePath = NodePath("../ChildScenes")


## 初始状态下是否激活第一个子场景（false = 全部休眠，由 LobbyWorld 户外作为主场景）
@export var activate_first_on_ready: bool = false


# ========================== 变量定义模块 ==========================
## 按场景节点名称（scene_id）索引：scene_id → Node2D
var _scene_by_id: Dictionary = {}

## 按场景文件路径索引：scene_file_path → Node2D
var _scene_by_path: Dictionary = {}

## 当前处于激活状态的 scene_id（空字符串表示无）
var _active_scene_id: String = "":
	get:
		return _active_scene_id

## 为 PiP 渲染而临时暴露的场景路径列表
var _pip_revealed: Array[String] = []

## 对 LobbyPortalManager 的缓存引用
var _portal_manager: Node = null


# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_portal_manager = get_parent().find_child("LobbyPortalManager", true, false)


# ========================== 公共 API：注册 / 发现 ==========================
## 功能：扫描 ChildScenes 节点下的所有子场景并自动注册
func discover_and_register() -> void:
	var container := _get_child_scenes_node()
	if not container:
		push_warning("[SubSceneManager] 未找到子场景容器节点: %s" % child_scenes_node_path)
		return

	for child in container.get_children():
		var scene_node := child as Node2D
		if not scene_node:
			continue

		var scene_id := scene_node.name
		register_sub_scene(scene_node, scene_id)

		# 初始全部休眠
		deactivate_scene(scene_id, true)

	# 可选：激活第一个场景
	if activate_first_on_ready and _scene_by_id.size() > 0:
		var first_id := _scene_by_id.keys()[0] as String
		activate_scene(first_id)


## 功能：注册单个子场景
## 参数：scene_node (Node2D) - 场景根节点；scene_id (String) - 唯一标识
func register_sub_scene(scene_node: Node2D, scene_id: String) -> void:
	if _scene_by_id.has(scene_id):
		push_warning("[SubSceneManager] 重复注册 scene_id: %s" % scene_id)
		return

	_scene_by_id[scene_id] = scene_node

	# 用场景文件路径建立二级索引
	var file_path := scene_node.scene_file_path
	if not file_path.is_empty():
		if _scene_by_path.has(file_path):
			push_warning("[SubSceneManager] 重复注册场景路径: %s" % file_path)
		else:
			_scene_by_path[file_path] = scene_node

	# 自动查找场景中的所有 PortalZone 并注册到 LobbyPortalManager
	_register_portal_zones(scene_node, scene_node)

	scene_registered.emit(scene_id, file_path)
	print("[SubSceneManager] 注册场景: %s (%s)" % [scene_id, file_path])


## 功能：注销子场景
## 参数：scene_id (String) - 要注销的场景 ID
func unregister_sub_scene(scene_id: String) -> void:
	var scene_node := _scene_by_id.get(scene_id) as Node2D
	if not scene_node:
		return

	# 从 PortalManager 注销该场景下的所有 PortalZone
	if _portal_manager and _portal_manager.has_method("unregister_portal"):
		for portal in _find_portal_zones(scene_node):
			_portal_manager.unregister_portal(portal)

	# 清理索引
	var file_path := scene_node.scene_file_path
	if not file_path.is_empty():
		_scene_by_path.erase(file_path)
	_scene_by_id.erase(scene_id)

	if _active_scene_id == scene_id:
		_active_scene_id = ""


# ========================== 公共 API：场景激活 / 休眠 ==========================
## 功能：激活目标场景（显示 + 启用处理）
## 参数：scene_id (String) - 场景标识
func activate_scene(scene_id: String) -> void:
	var scene := _scene_by_id.get(scene_id) as Node2D
	if not scene:
		push_warning("[SubSceneManager] 尝试激活未注册的场景: %s" % scene_id)
		return

	# 从 PiP 暴露列表中移除（已转为正式激活）
	_pip_revealed.erase(scene.scene_file_path)

	scene.show()
	# 恢复场景物理碰撞
	_enable_scene_collision(scene)
	_active_scene_id = scene_id
	scene_activated.emit(scene_id)


## 功能：休眠目标场景（隐藏 + 禁用处理）
## 参数：scene_id (String) - 场景标识；silent (bool) - 静默模式（初始化时使用）
func deactivate_scene(scene_id: String, silent: bool = false) -> void:
	var scene := _scene_by_id.get(scene_id) as Node2D
	if not scene:
		return

	scene.hide()
	# 禁用场景中所有物理碰撞，防止隐藏场景的碰撞体仍阻挡玩家
	_disable_scene_collision(scene)

	if _active_scene_id == scene_id:
		_active_scene_id = ""

	if not silent:
		scene_deactivated.emit(scene_id)


## 功能：切换到目标场景（休眠所有其他场景，激活目标场景）
## 参数：scene_id_or_path (String) - 场景 ID 或场景文件路径
func switch_to_scene(scene_id_or_path: String) -> void:
	# 尝试按路径查找，再按 ID 查找
	var scene := _scene_by_path.get(scene_id_or_path) as Node2D
	var scene_id := ""

	if scene:
		scene_id = scene.name
	else:
		scene = _scene_by_id.get(scene_id_or_path) as Node2D
		if scene:
			scene_id = scene_id_or_path

	if not scene:
		push_warning("[SubSceneManager] switch_to_scene 未找到场景: %s" % scene_id_or_path)
		return

	# 休眠所有其他场景
	for sid in _scene_by_id.keys():
		if sid != scene_id:
			deactivate_scene(sid)

	# 激活目标场景
	activate_scene(scene_id)


# ========================== 公共 API：PiP 预览支持 ==========================
## 功能：临时暴露目标场景供 PiP 摄像机渲染（不改变激活状态）
## 参数：scene_path (String) - 场景文件路径
func reveal_for_pip(scene_path: String) -> void:
	if scene_path.is_empty():
		return

	var scene := _scene_by_path.get(scene_path) as Node2D
	if not scene:
		return

	# 记录已暴露，避免重复隐藏
	if scene_path not in _pip_revealed:
		_pip_revealed.append(scene_path)

	scene.show()


## 功能：撤消 PiP 暴露（若场景未被激活则重新休眠）
## 参数：scene_path (String) - 场景文件路径
func conceal_from_pip(scene_path: String) -> void:
	if scene_path.is_empty():
		return

	_pip_revealed.erase(scene_path)

	var scene := _scene_by_path.get(scene_path) as Node2D
	if not scene:
		return

	# 仅在该场景不是当前激活场景时才隐藏
	if _active_scene_id != scene.name:
		scene.hide()


# ========================== 公共 API：查询接口 ==========================
## 功能：按 scene_id 获取场景根节点
func get_scene_by_id(scene_id: String) -> Node2D:
	return _scene_by_id.get(scene_id) as Node2D


## 功能：按场景文件路径获取场景根节点
func get_scene_by_path(scene_path: String) -> Node2D:
	return _scene_by_path.get(scene_path) as Node2D


## 功能：获取当前激活的场景 ID
func get_active_scene_id() -> String:
	return _active_scene_id


## 功能：获取所有已注册场景的 ID 列表
func get_all_scene_ids() -> Array[String]:
	return _scene_by_id.keys() as Array[String]


# ========================== 内部方法 ==========================
## 查找场景中所有的 PortalZone 并注册
func _register_portal_zones(scene_node: Node2D, scene_root: Node2D) -> void:
	if not _portal_manager or not _portal_manager.has_method("register_portal"):
		return

	for portal in _find_portal_zones(scene_node):
		_portal_manager.register_portal(portal, scene_root)


## 递归查找场景中所有 PortalZone 组件
func _find_portal_zones(scene_node: Node2D) -> Array[PortalZone]:
	var result: Array[PortalZone] = []
	# find_children 的第二个参数是类名，第三个参数 true 表示递归
	for child in scene_node.find_children("*", "PortalZone", true):
		var portal := child as PortalZone
		if portal:
			result.append(portal)
	return result


## 获取 ChildScenes 容器节点
func _get_child_scenes_node() -> Node:
	var node := get_node(child_scenes_node_path)
	if not node:
		push_error("[SubSceneManager] 子场景容器节点无效: %s" % child_scenes_node_path)
	return node

# ========================== 物理碰撞开关 ==========================
## 功能：禁用场景中所有物理碰撞（隐藏场景时调用）
func _disable_scene_collision(scene: Node2D) -> void:
	for child in scene.find_children("*", "CollisionShape2D", true):
		child.set_deferred("disabled", true)
	for child in scene.find_children("*", "CollisionPolygon2D", true):
		child.set_deferred("disabled", true)
	for child in scene.find_children("*", "Area2D", true):
		child.set_deferred("monitoring", false)
	for child in scene.find_children("*", "TileMapLayer", true):
		child.set_collision_enabled(false)


## 功能：恢复场景中所有物理碰撞（激活场景时调用）
func _enable_scene_collision(scene: Node2D) -> void:
	for child in scene.find_children("*", "CollisionShape2D", true):
		child.set_deferred("disabled", false)
	for child in scene.find_children("*", "CollisionPolygon2D", true):
		child.set_deferred("disabled", false)
	for child in scene.find_children("*", "Area2D", true):
		child.set_deferred("monitoring", true)
	for child in scene.find_children("*", "TileMapLayer", true):
		child.set_collision_enabled(true)

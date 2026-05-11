# ==============================================================================
#   lobby_portal_manager.gd
#   功能：传送管理器，基于子场景位置移动与透明度过渡的传送方案。
#        当玩家踏入传送方块时，将目标子场景移动到当前位置使两传送方块对齐，
#        源场景内容渐隐、目标场景内容渐显，实现无缝场景过渡。
#        传送期间玩家减速至固定值，场景按 z_index 分层确保正确遮挡。
#   挂载位置：作为 LobbyWorld 的子节点。
#   依赖：SubSceneManager（通过场景树获取）
# ==============================================================================
extends Node
class_name LobbyPortalManager

# ========================== 导出变量模块 ==========================
## 场景分层 z_index 偏移基数。目标场景在此基数上 +0，玩家（Entities）在此基数上 +1。
## 必须大于所有子场景中 Sprite2D 的总数，确保层间不重叠。
@export var z_layer_base: int = 1000


# ========================== 信号声明模块 ==========================
## 传送过渡开始
signal portal_transition_started(source_id: String, target_id: String)

## 踏入比例更新（0.0 ~ 1.0）
signal portal_transition_progress(progress: float)

## 传送完成，玩家已到达目标场景
signal portal_transition_completed(target_scene_path: String)

## 传送取消（玩家中途退出）
signal portal_transition_cancelled()


# ========================== 变量定义模块 ==========================
## 传送完成后阻止进度回调重新初始化（等待玩家完全退出后再允许重新进入）
var _completed_teleport: bool = false

## 传送网络注册表，key = "场景路径:传送方块ID"
## value = { "portal": PortalZone, "scene_node": Node2D }
var _portal_registry: Dictionary = {}

## PortalZone 实例到注册 key 的反向映射
var _portal_to_key: Dictionary = {}

## 是否正在过渡中
var _is_transitioning: bool = false

## 当前踏入比例
var _current_progress: float = 0.0

## 当前的源传送方块
var _source_portal: PortalZone = null

## 源传送方块所属场景的根节点
var _source_scene: Node2D = null

## 目标传送方块
var _target_portal: PortalZone = null

## 目标场景根节点
var _target_scene: Node2D = null

## 当前被跟踪的玩家
var _tracked_player: Player = null

## 是否已启用预览模式（目标场景已移动并开始透明度过渡）
var _preview_active: bool = false

## 子场景管理器的引用（延迟查找）
var _sub_scene_manager: Node = null

## Entities 节点引用（用于传送期间提升玩家 z_index）
var _entities_node: Node2D = null

## 已锁定传送方块集合（主动碰撞已禁用，等待玩家离开后恢复）
var _locked_portals: Dictionary = {}

## 本次传送的缓存偏移量（用于取消时恢复目标场景位置）
var _cached_offset: Vector2 = Vector2.ZERO

## 各子场景中非传送方块内容的 CanvasItem 缓存（scene_node → Array[CanvasItem]）
var _scene_content_items: Dictionary = {}

## 被修改过 z_index 的节点及其原始值（用于恢复）
var _saved_z_indices: Dictionary = {}

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_sub_scene_manager = get_parent().find_child("SubSceneManager", true, false)
	_entities_node = get_parent().find_child("Entities", true, false)

# ========================== 公共注册 API ==========================
## 功能：注册一个传送方块到全局网络
func register_portal(portal: PortalZone, scene_node: Node2D) -> void:
	var key := _make_key(scene_node.scene_file_path, portal.portal_id)
	if _portal_registry.has(key):
		push_warning("[PortalManager] 传送方块重复注册: %s" % key)
		return

	_portal_registry[key] = {
		"portal": portal,
		"scene_node": scene_node,
	}
	_portal_to_key[portal] = key

	# 缓存此场景的非传送方块视觉内容
	if not _scene_content_items.has(scene_node):
		_scene_content_items[scene_node] = _collect_content_items(scene_node)

	# 连接 PortalZone 信号
	portal.player_entered.connect(_on_player_entered_portal.bind(portal))
	portal.player_enter_progress.connect(_on_portal_progress.bind(portal))
	portal.player_exit.connect(_on_portal_exit.bind(portal))
	portal.portal_activated.connect(_on_portal_activated.bind(portal))


## 功能：注销传送方块（场景卸载时调用）
func unregister_portal(portal: PortalZone) -> void:
	if not _portal_to_key.has(portal):
		return

	var key := _portal_to_key[portal] as String
	_portal_registry.erase(key)
	_portal_to_key.erase(portal)

	if portal.player_entered.is_connected(_on_player_entered_portal.bind(portal)):
		portal.player_entered.disconnect(_on_player_entered_portal.bind(portal))
	if portal.player_enter_progress.is_connected(_on_portal_progress.bind(portal)):
		portal.player_enter_progress.disconnect(_on_portal_progress.bind(portal))
	if portal.player_exit.is_connected(_on_portal_exit.bind(portal)):
		portal.player_exit.disconnect(_on_portal_exit.bind(portal))
	if portal.portal_activated.is_connected(_on_portal_activated.bind(portal)):
		portal.portal_activated.disconnect(_on_portal_activated.bind(portal))


## 功能：清空所有注册（场景卸载时调用）
func clear_all_registrations() -> void:
	for entry in _portal_registry.values():
		var portal := (entry as Dictionary).get("portal") as PortalZone
		if portal and is_instance_valid(portal):
			unregister_portal(portal)
	_portal_registry.clear()
	_portal_to_key.clear()
	_locked_portals.clear()
	_scene_content_items.clear()


# ========================== 查询接口 ==========================
## 功能：根据源传送方块查询目标方块
func get_target_portal(source: PortalZone) -> PortalZone:
	var key := _make_key(source.target_scene_path, source.target_portal_id)
	var entry := _portal_registry.get(key, {}) as Dictionary
	return entry.get("portal", null) as PortalZone


## 功能：根据源传送方块查询目标场景根节点
func get_target_scene(source: PortalZone) -> Node2D:
	var key := _make_key(source.target_scene_path, source.target_portal_id)
	var entry := _portal_registry.get(key, {}) as Dictionary
	return entry.get("scene_node", null) as Node2D


# ========================== 信号回调模块 ==========================
## PortalZone.player_entered 回调 — 玩家刚踏入就立即启动场景重叠
func _on_player_entered_portal(_body: Node2D, portal: PortalZone) -> void:
	if _completed_teleport or _is_transitioning:
		return
	if _preview_active:
		return

	_source_portal = portal
	_source_scene = _find_scene_for_portal(portal)
	_target_portal = get_target_portal(portal)
	_target_scene = get_target_scene(portal)

	if not _target_portal or not _target_scene:
		return

	_preview_active = true
	_start_scene_overlap()
	
## PortalZone.player_enter_progress 回调
func _on_portal_progress(progress: float, body: Node2D, portal: PortalZone) -> void:
	if _completed_teleport:
		return
	if _is_transitioning:
		return

	if _tracked_player and _source_portal != portal:
		return

	if not _tracked_player or body != _tracked_player:
		return
	if not _target_portal or not _target_scene:
		return

	_current_progress = progress
	portal_transition_progress.emit(progress)

	# 控制玩家精灵透明度
	_update_player_visibility(progress)

	# 第一次超过阈值时启动场景重叠与透明度过渡
	if _preview_active:
		_update_scene_overlap(progress)


## PortalZone.player_exit 回调
func _on_portal_exit(_body: Node2D, portal: PortalZone) -> void:
	if _locked_portals.has(portal):
		portal.set_active_collision_enabled(true)
		_locked_portals.erase(portal)
	if _is_transitioning:
		return
	if _completed_teleport:         # ← 新增：传送已完成，仅清标志等待下次完整进出
		_completed_teleport = false
		return
	if _source_portal == null or portal != _source_portal:
		return
	_cancel_transition()


## PortalZone.portal_activated 回调
func _on_portal_activated(body: Node2D, portal: PortalZone) -> void:
	if _is_transitioning:
		return
	if portal != _source_portal:
		return

	_is_transitioning = true
	var player := body as Player
	if not player:
		_cancel_transition()
		return

	portal_transition_started.emit(portal.portal_id, portal.target_portal_id)
	_complete_transition(player)


# ========================== 场景重叠与透明度控制 ==========================
## 功能：启动场景重叠 — 移动目标子场景使其传送方块与源传送方块对齐，
##       并设置分层 z_index 确保目标场景在源场景之上、玩家在最上层
func _start_scene_overlap() -> void:
	if not _source_portal or not _target_portal or not _target_scene:
		return

	# 1) 计算偏移：源传送方块全局坐标 - 目标传送方块全局坐标
	_cached_offset = _source_portal.global_position - _target_portal.global_position

	# 2) 增量移动目标场景（基于当前位置叠加，非回退到原始位置）
	_target_scene.position += _cached_offset

	# 3) 确保目标场景可见（通过 SubSceneManager 暴露，不改变激活状态）
	if _sub_scene_manager and _sub_scene_manager.has_method("reveal_for_pip"):
		_sub_scene_manager.reveal_for_pip(_source_portal.target_scene_path)
	else:
		_target_scene.show()

	# 4) 设置分层 z_index：目标场景在源场景之上，玩家在最顶层
	_set_layer_z_index(_source_scene, 0)          # 底层 — 源场景
	_set_layer_z_index(_target_scene, z_layer_base)  # 中层 — 目标场景
	if _entities_node:
		_set_layer_z_index(_entities_node, z_layer_base * 2)  # 顶层 — 玩家

	# 5) 根据当前进度更新透明度
	_update_scene_overlap(_current_progress)


## 功能：保存节点原始 z_index 并设置新值
func _set_layer_z_index(node: Node2D, z: int) -> void:
	if not node or not is_instance_valid(node):
		return
	if not _saved_z_indices.has(node):
		_saved_z_indices[node] = node.z_index
	node.z_index = z


## 功能：更新场景透明度（源场景渐隐、目标场景渐显）
func _update_scene_overlap(progress: float) -> void:
	if _source_scene:
		_set_scene_opacity(_source_scene, 1.0 - progress)
	if _target_scene:
		_set_scene_opacity(_target_scene, progress)


## 功能：设置场景中非传送方块内容的透明度
func _set_scene_opacity(scene_node: Node2D, opacity: float) -> void:
	var items :Array[CanvasItem] = _scene_content_items.get(scene_node)
	if items == null:
		items = _collect_content_items(scene_node)
		_scene_content_items[scene_node] = items
	for item in items:
		if is_instance_valid(item):
			item.modulate.a = opacity


## 功能：恢复场景内容为完全不透明
func _reset_scene_opacity(scene_node: Node2D) -> void:
	_set_scene_opacity(scene_node, 1.0)


# ========================== 玩家控制 ==========================
## 功能：控制当前场景玩家精灵透明度（踏入时渐隐，保留最低透明度）
func _update_player_visibility(progress: float) -> void:
	if not _tracked_player or not is_instance_valid(_tracked_player):
		return
	_tracked_player.modulate.a = 1.0 - progress


# ========================== z_index 与速度恢复 ==========================
## 功能：恢复所有被临时修改的 z_index 到原始值
func _restore_all_z_indices() -> void:
	for node in _saved_z_indices:
		if is_instance_valid(node):
			node.z_index = _saved_z_indices[node]
	_saved_z_indices.clear()

# ========================== 传送完成与取消 ==========================
## 功能：完成传送 — 切换玩家场景位置、激活/休眠子场景。
##       采用两步式安全切换策略：
##       1) 先将玩家重定位到目标传送方块的安全中心
##       2) 再用 call_deferred 将碰撞开关推迟到下一帧，
##          确保源碰撞彻底关闭后才启用目标碰撞，防止玩家被卡住。
func _complete_transition(player: Player) -> void:
	if not _source_portal or not _target_portal:
		_cancel_transition()
		return

	player.modulate.a = 1.0

	# 恢复所有场景的 z_index
	_restore_all_z_indices()

	# 恢复所有场景透明度
	if _source_scene:
		_reset_scene_opacity(_source_scene)
	if _target_scene:
		_reset_scene_opacity(_target_scene)

	# 用 call_deferred 将场景碰撞切换延迟到下一帧执行
	# 这样源场景碰撞会先被禁用，目标碰撞后才启用，不存在重叠窗口
	call_deferred("_deferred_switch_scenes")


	# 禁用两个 portal 的 active collision，并加入锁定集合
	if _source_portal and is_instance_valid(_source_portal):
		_source_portal.set_active_collision_enabled(false)
		_locked_portals[_source_portal] = true
		_source_portal.reset_tracking()
	if _target_portal and is_instance_valid(_target_portal):
		_target_portal.set_active_collision_enabled(false)
		_locked_portals[_target_portal] = true
		_target_portal.reset_tracking()

	# 标记传送已完成
	_completed_teleport = true

	portal_transition_completed.emit(_source_portal.target_scene_path)
	print("[PortalManager] 传送完成: %s → %s" % [_source_portal.portal_id, _source_portal.target_portal_id])


## 功能：延迟到下一帧执行的场景碰撞切换。
##        此时源场景碰撞已完全禁用（_disable_scene_collision 中使用
##        set_deferred 已于帧末生效），再启用目标碰撞不会产生重叠。
func _deferred_switch_scenes() -> void:
	if _sub_scene_manager and _sub_scene_manager.has_method("switch_to_scene"):
		_sub_scene_manager.switch_to_scene(_source_portal.target_scene_path)
	elif _source_scene and _target_scene:
		_source_scene.hide()
		_target_scene.show()

	_cleanup_transition_state()


## 功能：取消传送 — 恢复原状
func _cancel_transition() -> void:
	var target_path := _source_portal.target_scene_path if _source_portal else ""

	# 恢复玩家可见性
	if _tracked_player and is_instance_valid(_tracked_player):
		_tracked_player.modulate.a = 1.0

	# 恢复源场景透明度
	if _source_scene and is_instance_valid(_source_scene):
		_reset_scene_opacity(_source_scene)

	# 恢复目标场景位置和透明度
	if _target_scene and is_instance_valid(_target_scene):
		_target_scene.position -= _cached_offset  # 撤销本次移动
		_reset_scene_opacity(_target_scene)

	# 恢复所有场景的 z_index
	_restore_all_z_indices()

	# 重新隐藏被暴露的目标场景
	if not target_path.is_empty() and _sub_scene_manager and _sub_scene_manager.has_method("conceal_from_pip"):
		_sub_scene_manager.conceal_from_pip(target_path)
	elif _target_scene and is_instance_valid(_target_scene):
		_target_scene.hide()

	portal_transition_cancelled.emit()
	_cleanup_transition_state()


## 功能：统一清理过渡状态
func _cleanup_transition_state() -> void:
	_is_transitioning = false
	_preview_active = false
	_current_progress = 0.0
	_cached_offset = Vector2.ZERO
	_source_portal = null
	_source_scene = null
	_target_portal = null
	_target_scene = null
	_tracked_player = null


# ========================== 内部辅助方法 ==========================
## 功能：查找指定 PortalZone 所属的场景根节点
func _find_scene_for_portal(portal: PortalZone) -> Node2D:
	var key := _portal_to_key.get(portal) as String
	if key:
		var entry := _portal_registry.get(key, {}) as Dictionary
		return entry.get("scene_node") as Node2D
	return null


## 功能：收集场景中所有不属于传送方块的视觉叶子节点
##       用于透明度控制，排除 PortalZone 及其子树的 Sprite2D/AnimatedSprite2D/TileMapLayer
static func _collect_content_items(scene_node: Node2D) -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	_collect_recursive(scene_node, result)
	return result


static func _collect_recursive(node: Node2D, result: Array[CanvasItem]) -> void:
	for child in node.get_children():
		if child is PortalZone or child.is_in_group("iso_sort_ignore"):
			continue
		if child is Sprite2D or child is AnimatedSprite2D or child is TileMapLayer:
			result.append(child)
		elif child is Node2D:
			_collect_recursive(child, result)


## 功能：构建注册表 key
static func _make_key(scene_path: String, portal_id: String) -> String:
	return scene_path + ":" + portal_id

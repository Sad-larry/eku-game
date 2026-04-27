# autoloads/room_manager.gd
extends Node


# 调试开关
const DEBUG_MODE: bool = true

# ========================== 全局变量 ==========================
# 房间管理核心数据
var registered_rooms: Dictionary = {}  # 已注册房间: {room_id: room_node}
var current_room_id: String = ""       # 当前激活的房间ID


# ===================== 房间管理核心方法 =====================
## 注册房间到全局管理器
## @param room_node: 房间节点（需继承Node2D，包含room_id属性）
func register_room(room_node: RoomBase) -> void:
	var room_id: String = room_node.room_id
	# 防止重复注册
	if registered_rooms.has(room_id):
		push_warning("[RoomManager] 房间已注册: %s" % room_id)
		return
		
	# 注册房间并绑定清理信号
	registered_rooms[room_id] = room_node
	# 注意：tree_exiting 连接使用 callable，避免匿名函数捕获问题
	room_node.tree_exiting.connect(_on_room_tree_exiting.bind(room_node))
	if DEBUG_MODE:
		print("[RoomManager] 注册房间: %s" % room_id)
		
## 内部处理房间树退出信号
func _on_room_tree_exiting(room_node: Node) -> void:
	unregister_room(room_node)
	
## 注销房间
## @param room_node: 要注销的房间节点
func unregister_room(room_node: RoomBase) -> void:
	if not is_instance_valid(room_node):
		return
	if room_node.get("room_id") == null:
		push_warning("[RoomManager] 房间节点缺少 room_id 属性: %s" % room_node.name)
		return
	
	var room_id: String = room_node.room_id
	# 移除注册记录
	if registered_rooms.has(room_id):
		registered_rooms.erase(room_id)
		# 如果注销的是当前房间，清空当前房间ID
		if current_room_id == room_id:
			current_room_id = ""
		
		if DEBUG_MODE:
			print("[RoomManager] 注销房间: %s" % room_id)
	else:
		push_warning("[RoomManager] 尝试注销未注册的房间: %s" % room_id)

## 设置当前激活的房间
## @param room_id: 房间唯一标识
## @return bool: 是否设置成功
func set_current_room(room_id: String) -> bool:
	# 校验房间是否已注册
	if not registered_rooms.has(room_id):
		push_error("[RoomManager] 无法设置当前房间，未注册的房间ID: %s" % room_id)
		return false
	
	# 休眠上一个房间
	if current_room_id != "" and registered_rooms.has(current_room_id):
		var prev_room = registered_rooms[current_room_id]
		if prev_room.has_method("deactivate_room"):
			prev_room.deactivate_room()
	
	# 激活新房间
	var new_room = registered_rooms[room_id]
	current_room_id = room_id
	if new_room.has_method("activate_room"):
		new_room.activate_room()
	
	# 全局状态同步（切换到游戏中）
	if GameManager.current_game_state != GameManager.GameState.IN_GAME:
		GameManager.set_game_state(GameManager.GameState.IN_GAME)
	
	if DEBUG_MODE:
		print("[RoomManager] 设置当前房间为: %s" % room_id)
	return true

# ===================== 辅助方法 =====================
## 获取当前房间节点
func get_current_room() -> RoomBase:
	if registered_rooms.has(current_room_id):
		return registered_rooms[current_room_id]
	return null

## 通过ID获取房间节点
func get_room_by_id(room_id: String) -> RoomBase:
	return registered_rooms.get(room_id, null)

## 清空所有房间注册（场景切换时调用）
func clear_all_rooms() -> void:
	# 先断开所有房间的 tree_exiting 连接，避免在清除过程中触发注销
	for room_node in registered_rooms.values():
		if is_instance_valid(room_node) and room_node.is_inside_tree():
			# 断开 tree_exiting 信号，防止循环修改
			if room_node.tree_exiting.is_connected(_on_room_tree_exiting.bind(room_node)):
				room_node.tree_exiting.disconnect(_on_room_tree_exiting.bind(room_node))
			room_node.queue_free()
	
	registered_rooms.clear()
	current_room_id = ""
	if DEBUG_MODE:
		print("[RoomManager] 已清空所有房间")

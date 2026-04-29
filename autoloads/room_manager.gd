# ==============================================================================
#   room_manager.gd
#   功能：房间全局管理器（Autoload 单例），负责房间的注册/注销、当前房间切换、
#        房间激活/休眠管理，并提供房间查询接口。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 RoomManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 调试模式开关（开启后输出更多调试信息）
const DEBUG_MODE: bool = true

# ========================== 变量定义模块 ==========================
## 已注册的房间字典：{room_id (String): room_node (RoomBase)}
var registered_rooms: Dictionary = {}

## 当前激活的房间 ID
var current_room_id: String = ""

# ========================== 公共 API 模块 ==========================
## 功能：注册房间到全局管理器
## 参数：room_node (RoomBase) - 继承自 RoomBase 的房间节点
## 说明：防止重复注册，并绑定节点的 tree_exiting 信号用于自动注销
func register_room(room_node: RoomBase) -> void:
	var room_id: String = room_node.room_id
	
	# 防止重复注册
	if registered_rooms.has(room_id):
		push_warning("[RoomManager] 房间已注册: %s" % room_id)
		return
	
	# 注册房间并绑定清理信号
	registered_rooms[room_id] = room_node
	# 注意：tree_exiting 连接使用 callable 绑定参数，避免匿名函数捕获问题
	room_node.tree_exiting.connect(_on_room_tree_exiting.bind(room_node))
	
	if DEBUG_MODE:
		print("[RoomManager] 注册房间: %s" % room_id)

## 功能：注销房间
## 参数：room_node (RoomBase) - 要注销的房间节点
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
		
		# 如果注销的是当前房间，清空当前房间 ID
		if current_room_id == room_id:
			current_room_id = ""
		
		if DEBUG_MODE:
			print("[RoomManager] 注销房间: %s" % room_id)
	else:
		push_warning("[RoomManager] 尝试注销未注册的房间: %s" % room_id)

## 功能：设置当前激活的房间
## 参数：room_id (String) - 房间唯一标识
## 返回值：bool - true 表示设置成功，false 表示失败
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

## 功能：获取当前房间节点
## 返回值：RoomBase - 当前房间实例，若未找到则返回 null
func get_current_room() -> RoomBase:
	if registered_rooms.has(current_room_id):
		return registered_rooms[current_room_id]
	return null

## 功能：通过房间 ID 获取房间节点
## 参数：room_id (String) - 房间唯一标识
## 返回值：RoomBase - 房间实例，若未找到则返回 null
func get_room_by_id(room_id: String) -> RoomBase:
	return registered_rooms.get(room_id, null)

## 功能：清空所有房间注册（场景切换时调用）
## 说明：断开所有房间的信号连接并释放节点
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

## 功能：激活第一个房间（占位方法，后续实现）
## TODO: 实现根据场景路径或房间 ID 激活首个房间的逻辑
func activate_first_room() -> void:
	# Global.ROOM_01_SCENE_PATH 相关逻辑待实现
	pass

# ========================== 内部回调模块 ==========================
## 功能：房间节点树退出时的内部处理（自动注销房间）
## 参数：room_node (Node) - 正在退出的房间节点
func _on_room_tree_exiting(room_node: Node) -> void:
	unregister_room(room_node)

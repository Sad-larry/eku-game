# autoloads/global.gd
# 全局单例：全局信号总线、通用枚举、工具函数（如数学运算、类型转换），所有单例均可访问
extends Node

# ========================== 信号定义 ==========================
@warning_ignore_start("unused_signal")
signal health_updated(new_health: int, new_max_health: int)
signal energy_updated(new_energy: int, new_max_energy: int)
signal combo_updated(new_combo: int)
@warning_ignore_restore("unused_signal")

# ========================== 常量定义 ==========================
# 调试开关
const DEBUG_MODE: bool = true

const START_MENU_SCENE_PATH: String = "res://scenes/start/start_menu.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main/main_menu.tscn"
const ROOM_01_SCENE_PATH: String = "res://scenes/game/room_01/room_01.tscn"


# ========================== 全局变量 ==========================
# 房间管理核心数据
var registered_rooms: Dictionary = {}  # 已注册房间: {room_id: room_node}
var current_room_id: String = ""       # 当前激活的房间ID
var room_list: Array[String] = []      # 房间ID列表（用于房间切换）

# ========================== 生命周期 ==========================
func _ready() -> void:
	print("Global: 全局单例初始化完成")
	

# ===================== 房间管理核心方法 =====================
## 注册房间到全局管理器
## @param room_node: 房间节点（需继承Node2D，包含room_id属性）
func register_room(room_node: RoomBase) -> void:
	var room_id: String = room_node.room_id
	# 防止重复注册
	if registered_rooms.has(room_id):
		push_warning("Room already registered: %s" % room_id)
		return
		
	# 注册房间并绑定清理信号
	registered_rooms[room_id] = room_node
	room_list.append(room_id)
	room_node.tree_exiting.connect(func():
		unregister_room(room_node)  # 房间节点销毁时自动注销
	)

## 注销房间
## @param room_node: 要注销的房间节点
func unregister_room(room_node: RoomBase) -> void:
	if not room_node.has_meta("room_id"):
		push_warning("Room node missing 'room_id' property: %s" % room_node.name)
		return
	
	var room_id: String = room_node.room_id
	# 移除注册记录
	if registered_rooms.has(room_id):
		registered_rooms.erase(room_id)
		room_list.erase(room_id)
		# 如果注销的是当前房间，清空当前房间ID
		if current_room_id == room_id:
			current_room_id = ""
		
		push_warning("Unregistered room: %s" % room_id)
	else:
		push_warning("Attempted to unregister unregistered room: %s" % room_id)

## 设置当前激活的房间
## @param room_id: 房间唯一标识
## @return bool: 是否设置成功
func set_current_room(room_id: String) -> bool:
	# 校验房间是否已注册
	if not registered_rooms.has(room_id):
		push_error("Cannot set current room - unregistered ID: %s" % room_id)
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
	
	push_warning("Set current room to: %s" % room_id)
	return true

# ===================== 辅助方法（扩展） =====================
## 获取当前房间节点
func get_current_room() -> RoomBase:
	if registered_rooms.has(current_room_id):
		return registered_rooms[current_room_id]
	return null

## 通过ID获取房间节点
func get_room_by_id(room_id: String) -> RoomBase:
	if registered_rooms.has(room_id):
		return registered_rooms[room_id]
	return null

## 清空所有房间注册（场景切换时调用）
func clear_all_rooms() -> void:
	for room_id in registered_rooms:
		var room = registered_rooms[room_id]
		if room.is_inside_tree():
			room.queue_free()
	registered_rooms.clear()
	room_list.clear()
	current_room_id = ""

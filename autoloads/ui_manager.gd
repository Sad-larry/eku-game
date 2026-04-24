# ui_manager.gd
extends Node

# ========================== 资源预加载 ==========================
const NOTIFICATION_MSGBOX_SCENE = preload("uid://c43tgh2u63611")
const PAUSE_MENU_SCENE = preload("uid://b0to31obmue6u")
const SETTINGS_SCENE = preload("uid://c2l1texcrid4e")
const GAME_OVER_SCENE = preload("uid://c2dh8ol77s0lp")

# ========================== 资源实例变量 ==========================
var _pause_menu_instance: Node = null
var _settings_menu_instance: Node = null
var _game_over_instance: Node = null

var _ui_state_map: Dictionary = {
	PAUSE_MENU_SCENE: GameManager.GameState.PAUSED,
	SETTINGS_SCENE: GameManager.GameState.SETTINGS,
	GAME_OVER_SCENE: GameManager.GameState.GAME_OVER
	# 其他模态 UI 映射...
}

# ========================== 模态 UI 栈（手动关闭） ==========================
var _modal_stack: Array[Dictionary] = []  # [{scene: PackedScene, instance: Node, state: GameState}]

# ========================== 通知队列（自动消失） ==========================
var _notification_queue: Array[Dictionary] = []   # {text, duration}
var _is_showing_notification: bool = false

# ========================== 模态 UI 栈 API ==========================
func push_ui(ui_scene: PackedScene) -> Control:
	"""添加一个模态 UI 到栈顶（需要手动 pop 或自动监听销毁）"""
	var instance = ui_scene.instantiate()
	var state = _ui_state_map.get(ui_scene, null)
	get_tree().root.add_child(instance)
	_modal_stack.append({scene = ui_scene, instance = instance, state = state})
	# 自动管理状态栈
	if state != null:
		GameManager.push_state(state)
	# 监听 UI 自动销毁（如点击关闭按钮时会 queue_free），自动从栈中移除
	instance.tree_exited.connect(_on_ui_closed.bind(instance))
	return instance

func pop_ui() -> void:
	"""关闭栈顶的模态 UI（销毁实例，状态恢复由 _on_ui_closed 统一处理）"""
	if _modal_stack.is_empty():
		return
	var last_dict = _modal_stack.pop_back()
	var last_instance = last_dict.instance
	if last_instance and is_instance_valid(last_instance):
		last_instance.queue_free()
	
func remove_ui(ui_instance: Node) -> void:
	"""从 UI 栈中移除指定的 UI 实例（如果存在）并销毁，状态恢复由 _on_ui_closed 处理"""
	if not ui_instance or not is_instance_valid(ui_instance):
		return
	var found_idx = -1
	for i in range(_modal_stack.size()):
		if _modal_stack[i].instance == ui_instance:
			found_idx = i
			break
	if found_idx == -1:
		return
		
	var removed_dict = _modal_stack[found_idx]
	#_modal_stack.remove_at(found_idx)
	# 销毁实例（会触发 tree_exited，进入 _on_ui_closed）
	if removed_dict.instance and is_instance_valid(removed_dict.instance):
		removed_dict.instance.queue_free()
		

func _on_ui_closed(ui: Node):
	"""当 UI 自动销毁时，从栈中移除引用；如果是当前栈顶，则恢复上一个游戏状态"""
	if not ui or not is_instance_valid(ui):
		return
		
	# 查找该 UI 在栈中的位置
	var idx = -1
	for i in range(_modal_stack.size()):
		if _modal_stack[i].instance == ui:
			idx = i
			break
	if idx == -1:
		return  # 可能已经被清理过了
		
	var was_top = (idx == _modal_stack.size() - 1)
	var scene = _modal_stack[idx].scene
	
	# 从栈中移除该 UI 的记录
	_modal_stack.remove_at(idx)
	
	# 如果被销毁的 UI 是栈顶，且它对应一个需要状态管理的场景，则恢复之前的状态
	if was_top and scene and _ui_state_map.has(scene):
		GameManager.pop_state()   # 恢复上一个游戏状态
		
func _get_scene_from_instance(instance: Node) -> PackedScene:
	if instance and instance.scene_file_path:
		return load(instance.scene_file_path)
	return null

# ========================== 暂停菜单专用 ==========================
func open_pause_menu():
	_show_pause_menu()
	
func close_pause_menu():
	_hide_pause_menu()

func _show_pause_menu():
	# 避免重复创建
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		return
	_pause_menu_instance = push_ui(PAUSE_MENU_SCENE)

func _hide_pause_menu():
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		remove_ui(_pause_menu_instance)
		_pause_menu_instance = null
		
# ========================== 设置菜单专用 ==========================
func open_settings_menu():
	_show_settings_menu()

func close_settings_menu():
	_hide_settings_menu()

func _show_settings_menu() -> void:
	# 避免重复创建
	if _settings_menu_instance and is_instance_valid(_settings_menu_instance):
		return
	_settings_menu_instance = push_ui(SETTINGS_SCENE)
	
func _hide_settings_menu():
	if _settings_menu_instance and is_instance_valid(_settings_menu_instance):
		remove_ui(_settings_menu_instance)
		_settings_menu_instance = null
		
# ========================== 游戏结束专用 ==========================
func open_game_over():
	_show_game_over()

func close_game_over():
	_hide_game_over()

func _show_game_over() -> void:
	if _game_over_instance and is_instance_valid(_game_over_instance):
		return
	_game_over_instance = push_ui(GAME_OVER_SCENE)
	
func _hide_game_over():
	if _game_over_instance and is_instance_valid(_game_over_instance):
		remove_ui(_game_over_instance)
		_game_over_instance = null
	
# ========================== 通知队列 API ==========================
func show_message(text: String, duration: float = 2.0):
	"""添加一条通知到队列（按顺序显示）"""
	_notification_queue.append({text = text, duration = duration})
	if not _is_showing_notification:
		_show_next_notification()

func _show_next_notification():
	if _notification_queue.is_empty():
		_is_showing_notification = false
		return
	
	_is_showing_notification = true
	var msg = _notification_queue.pop_front()
	var notifi: NotificationMsgbox = NOTIFICATION_MSGBOX_SCENE.instantiate()
	get_tree().root.add_child(notifi)
	
	# 等待通知显示完成（自动淡出并销毁）
	await notifi.show_message(msg.text, msg.duration)
	await notifi.tree_exited   # 等待节点真正销毁
	_show_next_notification()

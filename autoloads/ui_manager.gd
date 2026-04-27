# autoloads/ui_manager.gd
extends Node

# ========================== 资源预加载 ==========================
const NOTIFICATION_MSGBOX_SCENE = preload("uid://c43tgh2u63611")
const PAUSE_MENU_SCENE = preload("uid://b0to31obmue6u")
const SETTINGS_SCENE = preload("uid://c2l1texcrid4e")
const GAME_OVER_SCENE = preload("uid://c2dh8ol77s0lp")

# ========================== 调试开关 ==========================
const DEBUG_MODE: bool = true

# ========================== 资源实例变量 ==========================
var _pause_menu_instance: Node = null
var _settings_menu_instance: Node = null
var _game_over_instance: Node = null

# ========================== 生命周期 ==========================
func _ready() -> void:
	# 连接输入管理器的暂停信号
	if InputManager.has_signal("pause_requested"):
		InputManager.pause_requested.connect(_on_pause_requested)

func _on_pause_requested() -> void:
	"""响应暂停键：切换暂停菜单的打开/关闭"""
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		close_pause_menu()
	else:
		open_pause_menu()

# 使用场景资源路径作为键
var _ui_state_map: Dictionary = {
	PAUSE_MENU_SCENE.resource_path: GameManager.GameState.PAUSED,
	SETTINGS_SCENE.resource_path: GameManager.GameState.SETTINGS,
	GAME_OVER_SCENE.resource_path: GameManager.GameState.GAME_OVER
	# 其他模态 UI 映射...
}

# ========================== 模态 UI 栈（手动关闭） ==========================
# [{scene: PackedScene, instance: Node, state: GameState}]
var _modal_stack: Array[Dictionary] = []

# ========================== 通知队列（自动消失） ==========================
 # {text, duration}
var _notification_queue: Array[Dictionary] = []
var _is_showing_notification: bool = false

# ========================== 模态 UI 栈 API ==========================
## 添加一个模态 UI 到栈顶（需要手动 pop 或自动监听销毁）
## 返回创建的 UI 实例
func push_ui(ui_scene: PackedScene) -> Control:
	var instance = ui_scene.instantiate()
	var scene_path = ui_scene.resource_path
	var state = _ui_state_map.get(scene_path, null)
	
	# 自动管理状态栈
	if state != null:
		GameManager.push_state(state)
	
	get_tree().root.add_child(instance)
	_modal_stack.append({scene_path = scene_path, instance = instance, state = state})
	
	# 监听 UI 自动销毁（如点击关闭按钮时会 queue_free），自动从栈中移除
	instance.tree_exited.connect(_on_ui_closed.bind(instance))
	return instance

## 关闭栈顶的模态 UI（销毁实例，状态恢复由 _on_ui_closed 统一处理）
func pop_ui() -> void:
	if _modal_stack.is_empty():
		return
	var top = _modal_stack.pop_back()
	if top.instance and is_instance_valid(top.instance):
		top.instance.queue_free()
	# 注意：不立即从栈中删除，等待 _on_ui_closed 回调清理
	
## 从 UI 栈中移除指定的 UI 实例（如果存在）并销毁，状态恢复由 _on_ui_closed 处理
func remove_ui(ui_instance: Node) -> void:
	if not ui_instance or not is_instance_valid(ui_instance):
		return
	var found_idx = -1
	for i in range(_modal_stack.size()):
		if _modal_stack[i].instance == ui_instance:
			found_idx = i
			break
	if found_idx == -1:
		return
		
	var record = _modal_stack[found_idx]
	if record.instance and is_instance_valid(record.instance):
		record.instance.queue_free()
	# 不在此时从栈中移除，等待 tree_exited 信号统一处理

## UI 自动销毁时的回调（清理栈记录并恢复状态）
func _on_ui_closed(ui: Node):
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
	var record = _modal_stack[idx]
	var scene_path = record.scene_path
	var state = record.state
	
	# 从栈中移除该 UI 的记录
	_modal_stack.remove_at(idx)
	
	# 如果被销毁的 UI 是栈顶，且它对应一个需要状态管理的场景，则恢复之前的状态
	if was_top and state != null and _ui_state_map.has(scene_path):
		GameManager.pop_state()   # 恢复上一个游戏状态
		
func _get_scene_from_instance(instance: Node) -> PackedScene:
	if instance and instance.scene_file_path:
		return load(instance.scene_file_path)
	return null

# ========================== 暂停菜单专用 ==========================
func open_pause_menu():
	# 避免重复创建
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		return
	_pause_menu_instance = push_ui(PAUSE_MENU_SCENE)

func close_pause_menu():
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		remove_ui(_pause_menu_instance)
		_pause_menu_instance = null
		
# ========================== 设置菜单专用 ==========================
func open_settings_menu() -> void:
	# 避免重复创建
	if _settings_menu_instance and is_instance_valid(_settings_menu_instance):
		return
	_settings_menu_instance = push_ui(SETTINGS_SCENE)
	
func close_settings_menu():
	if _settings_menu_instance and is_instance_valid(_settings_menu_instance):
		remove_ui(_settings_menu_instance)
		_settings_menu_instance = null
		
# ========================== 游戏结束专用 ==========================
func open_game_over() -> void:
	if _game_over_instance and is_instance_valid(_game_over_instance):
		return
	_game_over_instance = push_ui(GAME_OVER_SCENE)
	
func close_game_over():
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
	await notifi.tree_exited
	_show_next_notification()

# ==============================================================================
#   ui_manager.gd
#   功能：UI 管理器（Autoload 单例），负责所有 UI 界面（暂停菜单、设置菜单、
#        游戏结束界面、HUD、通知消息）的创建、显示、关闭和生命周期管理。
#        支持模态 UI 栈和通知队列机制。
#   自动加载配置：Project -> Project Settings -> Autoloads 中添加，命名为 UIManager
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 调试模式开关
const DEBUG_MODE: bool = true

# ========================== 资源预加载模块 ==========================
## 通知消息框场景
const NOTIFICATION_MSGBOX_SCENE = preload("uid://c43tgh2u63611")

## 暂停菜单场景
const PAUSE_MENU_SCENE = preload("uid://b0to31obmue6u")

## 设置菜单场景
const SETTINGS_SCENE = preload("uid://c2l1texcrid4e")

## 游戏结束界面场景
const GAME_OVER_SCENE = preload("uid://c2dh8ol77s0lp")

## HUD 界面场景
const HUD_SCENE = preload("uid://d2miww5iawxo")

# ========================== 变量定义模块 ==========================
## 暂停菜单实例
var _pause_menu_instance: Node = null

## 设置菜单实例
var _settings_menu_instance: Node = null

## 游戏结束界面实例
var _game_over_instance: Node = null

## HUD 实例
var _hud_instance: HUD = null

## 场景资源路径 -> 游戏状态映射表（用于自动状态管理）
var _ui_state_map: Dictionary = {
	PAUSE_MENU_SCENE.resource_path: GameManager.GameState.PAUSED,
	SETTINGS_SCENE.resource_path: GameManager.GameState.SETTINGS,
	GAME_OVER_SCENE.resource_path: GameManager.GameState.GAME_OVER
}

## 模态 UI 栈（手动关闭的界面）
## 栈中元素：{scene_path: String, instance: Node, state: GameState}
var _modal_stack: Array[Dictionary] = []

## 通知队列（自动消失的提示消息）
var _notification_queue: Array[Dictionary] = []  # {text: String, duration: float}

## 是否正在显示通知（防止并发显示）
var _is_showing_notification: bool = false

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时连接输入管理器的暂停请求信号
func _ready() -> void:
	if InputManager.has_signal("pause_requested"):
		InputManager.pause_requested.connect(_on_pause_requested)

## 功能：响应暂停键输入，切换暂停菜单的打开/关闭状态
func _on_pause_requested() -> void:
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		close_pause_menu()
	else:
		open_pause_menu()

# ========================== 模态 UI 栈核心 API ==========================
## 功能：将一个模态 UI 推入栈顶并显示
## 参数：ui_scene (PackedScene) - UI 场景资源
## 返回值：Control - 创建的 UI 实例
func push_ui(ui_scene: PackedScene) -> Control:
	var instance = ui_scene.instantiate()
	var scene_path = ui_scene.resource_path
	var state = _ui_state_map.get(scene_path, null)
	
	# 自动管理游戏状态栈（如打开暂停菜单时推入 PAUSED 状态）
	if state != null:
		GameManager.push_state(state)
	
	get_tree().root.add_child(instance)
	_modal_stack.append({scene_path = scene_path, instance = instance, state = state})
	
	# 监听 UI 自动销毁（如点击关闭按钮时调用 queue_free），自动从栈中移除
	instance.tree_exited.connect(_on_ui_closed.bind(instance))
	return instance

## 功能：关闭栈顶的模态 UI（销毁实例）
func pop_ui() -> void:
	if _modal_stack.is_empty():
		return
	var top = _modal_stack.pop_back()
	if top.instance and is_instance_valid(top.instance):
		top.instance.queue_free()
	# 注意：不立即从栈中删除记录，等待 _on_ui_closed 回调完成清理

## 功能：从 UI 栈中移除指定的 UI 实例并销毁
## 参数：ui_instance (Node) - 要移除的 UI 实例
func remove_ui(ui_instance: Node) -> void:
	if not ui_instance or not is_instance_valid(ui_instance):
		return
	
	# 查找 UI 实例在栈中的位置
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
	# 不在此时从栈中移除记录，等待 tree_exited 信号统一处理

## 功能：UI 节点销毁时的回调，清理栈记录并恢复游戏状态
## 参数：ui (Node) - 被销毁的 UI 实例
func _on_ui_closed(ui: Node) -> void:
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
		GameManager.pop_state()  # 恢复上一个游戏状态

# ========================== 暂停菜单专用 API ==========================
## 功能：打开暂停菜单
func open_pause_menu():
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		return
	_pause_menu_instance = push_ui(PAUSE_MENU_SCENE)

## 功能：关闭暂停菜单
func close_pause_menu():
	if _pause_menu_instance and is_instance_valid(_pause_menu_instance):
		remove_ui(_pause_menu_instance)
		_pause_menu_instance = null

# ========================== 设置菜单专用 API ==========================
## 功能：打开设置菜单
func open_settings_menu() -> void:
	if _settings_menu_instance and is_instance_valid(_settings_menu_instance):
		return
	_settings_menu_instance = push_ui(SETTINGS_SCENE)

## 功能：关闭设置菜单
func close_settings_menu():
	if _settings_menu_instance and is_instance_valid(_settings_menu_instance):
		remove_ui(_settings_menu_instance)
		_settings_menu_instance = null

# ========================== 游戏结束界面专用 API ==========================
## 功能：打开游戏结束界面
func open_game_over() -> void:
	if _game_over_instance and is_instance_valid(_game_over_instance):
		return
	_game_over_instance = push_ui(GAME_OVER_SCENE)

## 功能：关闭游戏结束界面
func close_game_over():
	if _game_over_instance and is_instance_valid(_game_over_instance):
		remove_ui(_game_over_instance)
		_game_over_instance = null

# ========================== HUD 专用 API ==========================
## 功能：显示 HUD 界面
func show_hud() -> void:
	if _hud_instance and is_instance_valid(_hud_instance):
		return
	_hud_instance = HUD_SCENE.instantiate()
	get_tree().root.add_child(_hud_instance)

## 功能：隐藏 HUD 界面
func hide_hud() -> void:
	if _hud_instance and is_instance_valid(_hud_instance):
		_hud_instance.queue_free()
		_hud_instance = null

# ========================== 通知队列 API ==========================
## 功能：添加一条通知消息到队列（按顺序依次显示）
## 参数：text (String) - 消息文本；duration (float) - 显示时长（秒），默认 2.0
func show_message(text: String, duration: float = 2.0) -> void:
	_notification_queue.append({text = text, duration = duration})
	if not _is_showing_notification:
		_show_next_notification()

## 功能：显示下一条通知消息（内部递归调用）
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

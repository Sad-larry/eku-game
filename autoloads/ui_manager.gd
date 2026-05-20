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
const NOTIFICATION_MSGBOX_SCENE = preload("res://prefabs/ui/notification_msgbox/notification_msgbox.tscn")
## 暂停菜单场景
const PAUSE_MENU_SCENE = preload("res://scenes/ui/pause_menu/pause_menu.tscn")
## 设置菜单场景
const SETTINGS_SCENE = preload("res://scenes/ui/settings/settings.tscn")
## 游戏结束界面场景
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over/game_over.tscn")
## HUD 界面场景
const HUD_SCENE = preload("res://scenes/ui/hud/hud.tscn")
## 技能选择面板场景
const SKILL_SELECTION_SCENE = preload("res://scenes/ui/skill_selection/skill_selection_dialog.tscn")
## 大厅商店场景
const LOBBY_SHOP_SCENE = preload("res://scenes/ui/lobby_shop/lobby_shop.tscn")
## 玩家成长面板场景
const PLAYER_PROGRESSION_SCENE = preload("res://scenes/ui/player_progression/player_progression_panel.tscn")
## 遗物选择面板场景
const RELIC_SELECTION_SCENE = preload("res://scenes/ui/relic_selection/relic_selection.tscn")
## 商人商店场景
const MERCHANT_SHOP_SCENE = preload("res://scenes/ui/merchant_shop/merchant_shop.tscn")
## 对话框场景
const DIALOG_BOX_SCENE = preload("res://scenes/ui/dialog_box/dialog_box.tscn")

# ========================== UI 注册表模块 ==========================
## UI 名称 -> 场景资源映射
const _UI_SCENES: Dictionary = {
	"pause_menu": PAUSE_MENU_SCENE,
	"settings_menu": SETTINGS_SCENE,
	"game_over": GAME_OVER_SCENE,
	"skill_selection": SKILL_SELECTION_SCENE,
	"lobby_shop": LOBBY_SHOP_SCENE,
	"player_progression": PLAYER_PROGRESSION_SCENE,
	"relic_selection": RELIC_SELECTION_SCENE,
	"merchant_shop": MERCHANT_SHOP_SCENE,
	"dialog_box": DIALOG_BOX_SCENE,
}

## UI 名称 -> 游戏状态映射（需要状态管理的 UI）
const _UI_STATE_MAP: Dictionary = {
	"pause_menu": GameManager.GameState.PAUSED,
	"settings_menu": GameManager.GameState.SETTINGS,
	"game_over": GameManager.GameState.GAME_OVER,
}

# ========================== 变量定义模块 ==========================
## UI 实例缓存：ui_name -> Node
var _ui_instances: Dictionary = {}
## HUD 实例（特殊处理，不在模态栈中）
var _hud_instance: HUD = null
## 模态 UI 栈（手动关闭的界面）
## 栈中元素：{ui_name: String, instance: Node}
var _modal_stack: Array[Dictionary] = []
## 通知队列（自动消失的提示消息）
var _notification_queue: Array[Dictionary] = []  # {text: String, duration: float}
## 是否正在显示通知（防止并发显示）
var _is_showing_notification: bool = false

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时连接信号
func _ready() -> void:
	EventBus.pause_menu_requested.connect(_on_ui_requested.bind("pause_menu"))
	EventBus.settings_menu_requested.connect(_on_ui_requested.bind("settings_menu"))
	EventBus.game_over_requested.connect(_on_ui_requested.bind("game_over"))
	EventBus.skill_selection_requested.connect(_on_ui_requested.bind("skill_selection"))
	EventBus.relic_selection_requested.connect(_on_relic_selection_requested)
	EventBus.return_to_main_menu_requested.connect(_on_return_to_main_menu)

	InputManager.pause_requested.connect(_on_pause_requested)
	GameManager.game_state_changed.connect(_on_game_state_changed)

## 功能：响应暂停键输入，切换暂停菜单的打开/关闭状态
func _on_pause_requested() -> void:
	if is_ui_open("pause_menu"):
		close_ui("pause_menu")
	else:
		open_ui("pause_menu")

# ========================== 模态 UI 栈核心 API ==========================
## 功能：将一个模态 UI 推入栈顶并显示
## 参数：ui_name (String) - UI 名称（必须在 _UI_SCENES 中注册）
##       setup_args (Array) - 传递给 UI 的 setup 方法的参数（可选）
## 返回值：Node - 创建的 UI 实例
func push_ui(ui_name: String, setup_args: Array = []) -> Node:
	var scene: PackedScene = _UI_SCENES.get(ui_name)
	if scene == null:
		push_warning("UIManager: 未知 UI 名称: %s" % ui_name)
		return null

	var instance = scene.instantiate()
	get_tree().root.add_child(instance)

	# 调用 setup 方法（如果存在）
	if not setup_args.is_empty() and instance.has_method("setup"):
		instance.setup.callv(setup_args)

	# 记录到模态栈
	_modal_stack.append({ui_name = ui_name, instance = instance})
	_ui_instances[ui_name] = instance

	# 监听 UI 自动销毁（如点击关闭按钮时调用 queue_free），自动从栈中移除
	instance.tree_exited.connect(_on_ui_closed.bind(ui_name, instance))

	# 请求游戏状态切换
	var state = _UI_STATE_MAP.get(ui_name)
	if state != null:
		EventBus.game_state_push_requested.emit(state)

	_update_input_blocking()
	return instance

## 功能：关闭栈顶的模态 UI（销毁实例）
func pop_ui() -> void:
	if _modal_stack.is_empty():
		return
	var top = _modal_stack.pop_back()
	if top.instance and is_instance_valid(top.instance):
		top.instance.queue_free()

## 功能：关闭指定名称的 UI
## 参数：ui_name (String) - UI 名称
func remove_ui_by_name(ui_name: String) -> void:
	var instance = _ui_instances.get(ui_name)
	if not instance or not is_instance_valid(instance):
		return

	# 查找并从栈中移除，记录是否为栈顶
	var was_top = false
	for i in range(_modal_stack.size()):
		if _modal_stack[i].ui_name == ui_name:
			was_top = (i == _modal_stack.size() - 1)
			_modal_stack.remove_at(i)
			break

	instance.queue_free()
	_ui_instances.erase(ui_name)
	_update_input_blocking()

	# 如果被销毁的 UI 是栈顶，且它对应一个需要状态管理的场景，则恢复之前的状态
	if was_top and _UI_STATE_MAP.has(ui_name):
		EventBus.game_state_pop_requested.emit()

## 功能：UI 节点销毁时的回调，清理栈记录（处理用户主动关闭对话框的情况）
## 参数：ui_name (String) - UI 名称；ui (Node) - 被销毁的 UI 实例
func _on_ui_closed(ui_name: String, ui: Node) -> void:
	# 清理缓存引用（处理用户主动关闭对话框时缓存未更新的情况）
	_ui_instances.erase(ui_name)

	# 查找该 UI 在栈中的位置
	var idx = -1
	for i in range(_modal_stack.size()):
		if _modal_stack[i].instance == ui:
			idx = i
			break

	if idx == -1:
		return  # 已被 remove_ui_by_name 清理过

	var was_top = (idx == _modal_stack.size() - 1)

	# 从栈中移除该 UI 的记录
	_modal_stack.remove_at(idx)
	_update_input_blocking()

	# 如果被销毁的 UI 是栈顶，且它对应一个需要状态管理的场景，则恢复之前的状态
	if was_top and _UI_STATE_MAP.has(ui_name):
		EventBus.game_state_pop_requested.emit()

# ========================== UI 打开/关闭通用 API ==========================
## 功能：打开指定名称的 UI
## 参数：ui_name (String) - UI 名称；setup_args (Array) - 传递给 setup 方法的参数
## 返回值：Node - UI 实例
func open_ui(ui_name: String, setup_args: Array = []) -> Node:
	# 防重复打开
	if is_ui_open(ui_name):
		return _ui_instances[ui_name]
	return push_ui(ui_name, setup_args)

## 功能：关闭指定名称的 UI
## 参数：ui_name (String) - UI 名称
func close_ui(ui_name: String) -> void:
	# HUD 特殊处理
	if ui_name == "hud":
		hide_hud()
		return
	remove_ui_by_name(ui_name)

## 功能：检查指定 UI 是否已打开
## 参数：ui_name (String) - UI 名称
## 返回值：bool - true 表示已打开
func is_ui_open(ui_name: String) -> bool:
	var instance = _ui_instances.get(ui_name)
	return instance != null and is_instance_valid(instance)

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

# ========================== 特殊 UI 专用 API ==========================
## 功能：打开遗物选择面板（需要传递参数）
## 参数：options (Array[RelicData]) - 遗物选项
## 返回值：Node - 遗物选择面板实例
func open_relic_selection(options: Array[RelicData]) -> Node:
	if is_ui_open("relic_selection"):
		return _ui_instances["relic_selection"]
	var instance := push_ui("relic_selection", [options])
	return instance

## 功能：收到遗物选择面板请求（默认从默认池随机 3 个）
func _on_relic_selection_requested() -> void:
	if is_ui_open("relic_selection"):
		return
	var pool: RelicPool = RelicManager.get_default_pool()
	if pool == null:
		push_warning("UIManager: 遗物池为空")
		return
	var options := pool.roll_relics(3)
	if options.is_empty():
		return
	open_relic_selection(options)

## 功能：收到 UI 请求（通用处理）
## 参数：ui_name (String) - UI 名称
func _on_ui_requested(ui_name: String) -> void:
	open_ui(ui_name)

# ========================== 通知队列 API ==========================
## 功能：添加一条通知消息到队列（按顺序依次显示）
## 参数：text (String) - 消息文本；duration (float) - 显示时长（秒），默认 2.0
func show_message(text: String, duration: float = 2.0) -> void:
	_notification_queue.append({text = text, duration = duration})
	if not _is_showing_notification:
		_show_next_notification()

## 功能：显示下一条通知消息（内部递归调用）
func _show_next_notification() -> void:
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

# ========================== UI 分发调度模块 ==========================
## 功能：遍历模态栈，收集所有 UI 的输入屏蔽规则，通知 InputManager
func _update_input_blocking() -> void:
	var blocked_prefixes: Array[String] = []
	for record in _modal_stack:
		var inst = record.instance
		if inst and inst.has_method("get_blocked_input_prefixes"):
			blocked_prefixes.append_array(inst.get_blocked_input_prefixes())
	EventBus.input_blocking_updated.emit(blocked_prefixes)

# ========================== 全局重置模块 ==========================
## 功能：监听 return_to_main_menu_requested 信号，
##        清空模态 UI 栈、所有缓存实例引用，并重置 GameManager 状态
func _on_return_to_main_menu() -> void:
	# 收集所有待销毁的 UI 实例
	var instances_to_free: Array[Node] = []
	for record in _modal_stack:
		if record.instance and is_instance_valid(record.instance):
			instances_to_free.append(record.instance)

	# 清空缓存和模态栈
	_ui_instances.clear()
	_modal_stack.clear()

	# 销毁所有 UI 实例
	for inst in instances_to_free:
		inst.queue_free()

	# 重置 GameManager 状态栈并切换到主菜单
	GameManager.clear_state_stack()
	GameManager.set_game_state(GameManager.GameState.MAIN_MENU)

	if DEBUG_MODE:
		print("[UIManager] 模态栈和所有 UI 实例已清空，游戏状态已重置为主菜单")

## 功能：游戏状态变化时的回调，控制 HUD 显示/隐藏和场景树暂停
## 参数：new_state (GameManager.GameState) - 新状态；_old_state (GameManager.GameState) - 旧状态
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	# 控制 HUD 显示/隐藏
	match new_state:
		GameManager.GameState.IN_GAME, GameManager.GameState.LOBBY:
			show_hud()
		GameManager.GameState.MAIN_MENU:
			hide_hud()
		_:
			hide_hud()

	# 控制场景树暂停/恢复
	if get_tree():
		match new_state:
			GameManager.GameState.PAUSED, GameManager.GameState.SETTINGS, GameManager.GameState.GAME_OVER:
				get_tree().paused = true
			GameManager.GameState.MAIN_MENU, GameManager.GameState.IN_GAME, GameManager.GameState.LOBBY:
				get_tree().paused = false

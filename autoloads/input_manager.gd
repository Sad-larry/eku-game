# autoloads/input_manager.gd
# 全局输入管理器：管理输入映射、输入缓冲、按键状态跟踪
# 自动加载配置：Project -> Project Settings -> Autoloads 中添加，命名为 InputManager
extends Node

# ========================== 常量定义 ==========================
# 调试开关
const DEBUG_MODE: bool = false

# 输入缓冲时长（毫秒）
const INPUT_BUFFER_DURATION_MS: int = 150

# 按键名 → Godot Key 枚举映射（用于 _setup_input_map 中注册 InputMap）
const KEY_NAME_MAP: Dictionary = {
	"A": KEY_A, "B": KEY_B, "C": KEY_C, "D": KEY_D,
	"E": KEY_E, "F": KEY_F, "P": KEY_P, "Q": KEY_Q,
	"S": KEY_S, "W": KEY_W, "Z": KEY_Z, "X": KEY_X,
	"1": KEY_1, "2": KEY_2, "3": KEY_3, "4": KEY_4,
	"Space": KEY_SPACE, "Enter": KEY_ENTER, "Escape": KEY_ESCAPE,
	"Backspace": KEY_BACKSPACE, "Tab": KEY_TAB,
	"Left Shift": KEY_SHIFT, "Right Shift": KEY_SHIFT,
	"Left Ctrl": KEY_CTRL, "Right Ctrl": KEY_CTRL,
	"Left Alt": KEY_ALT, "Right Alt": KEY_ALT,
	"Left Arrow": KEY_LEFT, "Right Arrow": KEY_RIGHT,
	"Up Arrow": KEY_UP, "Down Arrow": KEY_DOWN
}

# TODO 当暂停时，所有按键都禁用了，但是有没有一种可能，就是暂停进入设置或其他界面时
# 还是需要使用到按键进行快捷操作，例如，使用方向键或Tab键进行组件选择，使用回车键进行确认


const INPUT_ACTIONS := INPUTACTIONS.INPUT_ACTIONS_DICTIONARY

# ========================== 变量定义 ==========================
# 是否锁定输入（暂停/菜单时禁用）
var input_locked: bool = false
# 输入缓冲队列: Array[Dictionary{action: String, time_ms: int}]
var _buffer: Array[Dictionary] = []

# 辅助变量：用于暂停键的防抖（避免重复触发）
var _pause_key_just_handled: bool = false
# 缓存的非 axis 动作名列表（避免每帧遍历字典）
var _action_names: Array[String] = []
# 上一帧的移动向量（用于检测变化后发射信号）
var _last_movement: Vector2 = Vector2.ZERO

# ========================== 信号定义 ==========================
# 通用输入触发（所有 action 类型动作按下时发射）
signal action_triggered(action_name: String)
# 移动向量变化（与上一帧不同时发射）
signal movement_vector_changed(direction: Vector2)
# 输入锁定状态变更
signal input_lock_changed(is_locked: bool)
# 请求打开/关闭暂停菜单（解耦 UIManager）
signal pause_requested()

# ========================== 初始化 ==========================
func _ready() -> void:
	_setup_input_map()
	_cache_action_names()
	_connect_game_state()
	if DEBUG_MODE:
		print("InputManager: 初始化完成，已注册 ", _action_names.size(), " 个可检测动作")

func _setup_input_map() -> void:
	"""遍历 INPUT_ACTIONS，将未在 project.godot 中注册的按键补注册到 InputMap"""
	for action_name: String in INPUT_ACTIONS:
		var config: Dictionary = INPUT_ACTIONS[action_name]
		if InputMap.has_action(action_name):
			continue
		InputMap.add_action(action_name)
		for key_name: String in config["keyboard"]:
			_register_key(action_name, key_name)
		if DEBUG_MODE:
			print("[InputManager] InputMap 补注册: ", action_name)

func _register_key(action_name: String, key_name: String) -> void:
	"""将单个按键名注册到 InputMap 动作"""
	if key_name.contains("Mouse"):
		var button_index: int = MOUSE_BUTTON_LEFT if "Left" in key_name else MOUSE_BUTTON_RIGHT
		var event_btn := InputEventMouseButton.new()
		event_btn.button_index = button_index as MouseButton
		event_btn.double_click = false
		InputMap.action_add_event(action_name, event_btn)
		return

	var key: Key = KEY_NAME_MAP.get(key_name, KEY_NONE)
	if key == KEY_NONE:
		if DEBUG_MODE:
			push_warning("[InputManager] 未知按键名: ", key_name, "（动作: ", action_name, "）")
		return
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)

func _cache_action_names() -> void:
	"""缓存非 axis、非 pause 的动作名列表，供 _detect_actions 每帧遍历"""
	for action_name: String in INPUT_ACTIONS:
		var config: Dictionary = INPUT_ACTIONS[action_name]
		if config["type"] == "axis" or action_name == "pause":
			continue
		_action_names.append(action_name)

func _connect_game_state() -> void:
	if not GameManager:
		if DEBUG_MODE:
			print("[InputManager] 警告: GameManager 未找到，输入锁定将不会自动响应游戏状态")
		return

	if GameManager.has_signal("game_state_changed"):
		GameManager.game_state_changed.connect(_on_game_state_changed)
		_on_game_state_changed(GameManager.current_game_state, GameManager.current_game_state)

# ========================== 输入状态更新 ==========================
func _process(_delta: float) -> void:
	_handle_pause_input()
	_detect_actions()
	_emit_movement_vector()
	_clean_expired_buffer()

func _handle_pause_input() -> void:
	"""单独处理暂停键，确保在锁定状态下也能响应（但根据游戏状态决定是否生效）"""
	if not Input.is_action_just_pressed("pause"):
		_pause_key_just_handled = false
		return

	if _pause_key_just_handled:
		return
	_pause_key_just_handled = true

	pause_requested.emit()
	if DEBUG_MODE:
		print("[InputManager] pause_requested 信号发出")

func _detect_actions() -> void:
	"""遍历 _action_names，检测按键按下后自动缓冲并发射 action_triggered 信号"""
	if input_locked:
		return
	for action_name: String in _action_names:
		if Input.is_action_just_pressed(action_name):
			var config: Dictionary = INPUT_ACTIONS[action_name]
			if config["bufferable"]:
				buffer_input(action_name)
			action_triggered.emit(action_name)
			if DEBUG_MODE:
				print("[InputManager] action_triggered: ", action_name)

func _emit_movement_vector() -> void:
	"""检测移动向量变化并发射 signal"""
	if input_locked:
		if _last_movement != Vector2.ZERO:
			_last_movement = Vector2.ZERO
			movement_vector_changed.emit(Vector2.ZERO)
		return
	var vec: Vector2 = get_movement_vector()
	if vec != _last_movement:
		_last_movement = vec
		movement_vector_changed.emit(vec)

# ========================== 输入缓冲核心接口 ==========================
func buffer_input(action: String) -> bool:
	if input_locked:
		return false
	var config = INPUT_ACTIONS.get(action)
	if not config or not config["bufferable"]:
		return false

	var now_ms = Time.get_ticks_msec()
	if _buffer.size() > 0:
		var last = _buffer[-1]
		if last["action"] == action and (now_ms - last["time_ms"]) < 50:
			return false

	_buffer.append({ "action": action, "time_ms": now_ms })
	if DEBUG_MODE:
		print("[InputManager] 缓冲 + ", action, " 队列长度: ", _buffer.size())
	return true

func get_buffered_input() -> String:
	_clean_expired_buffer()

	if _buffer.is_empty() or input_locked:
		return ""

	var entry = _buffer.pop_front()
	return entry.action

func clear_buffer(action: String = "") -> void:
	if action.is_empty():
		_buffer.clear()
	else:
		_buffer = _buffer.filter(func(e): return e.action != action)

func _clean_expired_buffer() -> void:
	var now_ms = Time.get_ticks_msec()
	var i = 0
	while i < _buffer.size():
		if now_ms - _buffer[i]["time_ms"] > INPUT_BUFFER_DURATION_MS:
			_buffer.remove_at(i)
		else:
			i += 1

# ========================== 输入状态查询接口 ==========================
func get_movement_vector() -> Vector2:
	if input_locked:
		return Vector2.ZERO
	var vec = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	return vec.limit_length(1.0)

func is_action_just_pressed(action: String) -> bool:
	return not input_locked and Input.is_action_just_pressed(action)

func is_action_pressed(action: String) -> bool:
	return not input_locked and Input.is_action_pressed(action)

func is_action_just_released(action: String) -> bool:
	return not input_locked and Input.is_action_just_released(action)

# ========================== 输入锁定控制 ==========================
func set_input_lock(locked: bool) -> void:
	if input_locked == locked:
		return
	input_locked = locked
	input_lock_changed.emit(locked)
	if locked:
		clear_buffer()
	if DEBUG_MODE:
		print("[InputManager] 输入锁定状态 -> ", locked)

# ========================== 游戏状态回调 ==========================
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.MAIN_MENU,\
		GameManager.GameState.LOBBY,\
		GameManager.GameState.SETTINGS,\
		GameManager.GameState.PAUSED,\
		GameManager.GameState.GAME_OVER:
			set_input_lock(true)
		GameManager.GameState.IN_GAME:
			set_input_lock(false)
		_:
			set_input_lock(false)

# ========================== 调试输入打印 ==========================
func _input(event: InputEvent) -> void:
	if not DEBUG_MODE or input_locked:
		return
	if event.is_pressed() and not event.is_echo():
		print("[InputManager] 按键: ", event.as_text())

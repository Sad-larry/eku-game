# ==============================================================================
#   input_manager.gd
#   功能：全局输入管理器（Autoload 单例），负责输入缓冲、按键状态跟踪、
#        移动向量检测、输入锁定控制（根据游戏状态自动锁定/解锁），并解耦提供输入查询接口。
#   自动加载配置：Project -> Project Settings -> Autoloads 中添加，命名为 InputManager
# ==============================================================================
extends Node

# ========================== 信号声明模块 ==========================
## 触发时机：任何非轴动作（action 类型）被按下时触发
## 参数：action_name (String) - 动作名称
signal action_triggered(action_name: String)

## 触发时机：移动向量与上一帧不同时触发
## 参数：direction (Vector2) - 当前移动方向（单位向量）
signal movement_vector_changed(direction: Vector2)

## 触发时机：输入锁定状态发生变化时触发
## 参数：is_locked (bool) - true 表示输入锁定，false 表示输入解锁
signal input_lock_changed(is_locked: bool)

## 触发时机：用户按下暂停键时触发（用于解耦 UIManager）
signal pause_requested()

# ========================== 常量定义模块 ==========================
## 调试模式开关（开启后输出更多调试信息）
const DEBUG_MODE: bool = false
## 输入缓冲时长（毫秒），超过此时长的缓冲输入将失效
const INPUT_BUFFER_DURATION_MS: int = 150
## 输入动作配置字典（从 INPUTACTIONS 资源导入）
const INPUT_ACTIONS := InputActions.INPUT_ACTIONS_DICTIONARY

# ========================== TODO 待完善项 ==========================
## TODO: 当暂停时，所有按键都禁用了，但是有没有一种可能，就是暂停进入设置或其他界面时
##       还是需要使用到按键进行快捷操作，例如，使用方向键或 Tab 键进行组件选择，使用回车键进行确认
##       当前实现中暂停状态下 input_locked = true 会屏蔽所有非暂停键，
##       后续可根据需求为 UI 操作单独保留特定动作的输入权限

# ========================== 变量定义模块 ==========================
## 是否锁定输入（暂停/菜单/游戏结束时禁用大部分输入）
var input_locked: bool = true
## 输入缓冲队列，存储 Dictionary{action: String, time_ms: int}
var _buffer: Array[Dictionary] = []
## 缓存的非轴动作名列表（避免每帧遍历全部字典）
var _action_names: Array[String] = []
## 上一帧的移动向量（用于检测变化后发射信号）
var _last_movement: Vector2 = Vector2.ZERO
## 被阻塞的输入动作前缀列表
var _blocked_action_prefixes: Array[String] = []

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时执行初始化（注册 InputMap、缓存动作名、连接游戏状态信号）
func _ready() -> void:
	_cache_action_names()
	_connect_game_state()
	EventBus.input_blocking_updated.connect(_on_input_blocking_updated)
	if DEBUG_MODE:
		print("InputManager: 初始化完成，已注册 ", _action_names.size(), " 个可检测动作")

## 功能：接收 GUI 未消费的输入事件，检测游戏动作（天然解决 UI 贯穿问题）
func _unhandled_input(event: InputEvent) -> void:
	_handle_pause_input()
	_detect_actions(event)

## 功能：每帧更新（处理暂停输入、动作检测、移动向量检测、缓冲过期清理）
func _process(_delta: float) -> void:
	_emit_movement_vector()
	_clean_expired_buffer()

## 功能：原始输入事件处理（调试模式下打印所有按键）
func _input(event: InputEvent) -> void:
	if not DEBUG_MODE or input_locked:
		return
	if event.is_pressed() and not event.is_echo():
		print("[InputManager] 按键: ", event.as_text())

# ========================== 初始化辅助方法模块 ==========================
## 功能：缓存非轴、非暂停的动作名列表（供每帧遍历）
func _cache_action_names() -> void:
	for action_name: String in INPUT_ACTIONS:
		var config: Dictionary = INPUT_ACTIONS[action_name]
		# 跳过轴类型动作和暂停动作（暂停单独处理）
		if config["type"] == "axis" or action_name == "pause":
			continue
		_action_names.append(action_name)

## 功能：连接 GameManager 的游戏状态变化信号，实现自动输入锁定
func _connect_game_state() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	_on_game_state_changed(GameManager.current_game_state, GameManager.current_game_state)

# ========================== 输入状态更新核心模块 ==========================
## 功能：单独处理暂停键，确保在锁定状态下也能响应（但根据游戏状态决定是否生效）
func _handle_pause_input() -> void:
	if Input.is_action_just_pressed("pause"):
		pause_requested.emit()
		if DEBUG_MODE:
			print("[InputManager] pause_requested 信号发出")

## 功能：遍历动作名列表，检测按键按下后自动缓冲并发射 action_triggered 信号
## 说明：单个事件最多触发一个动作，匹配后立即返回。
##       attack 动作特殊处理：在按键释放时触发（而非按下），
##       配合 MouseSwipeDetector 的事件消费机制区分"点击"（攻击）和"拖拽"（滑动）。
func _detect_actions(event: InputEvent) -> void:
	if input_locked:
		return
	for action_name: String in _action_names:
		if _is_action_blocked(action_name):
			continue

		# attack 使用释放触发：滑动检测器会在拖拽时消费 mouse-up 事件，
		# 阻止此方法被调用，从而区分点击（攻击）和拖拽（滑动）。
		var detected: bool = false
		if action_name == "attack":
			detected = event.is_action_released(action_name)
		else:
			detected = event.is_action_pressed(action_name)

		if detected:
			var config: Dictionary = INPUT_ACTIONS[action_name]
			# 若该动作支持输入缓冲，则存入缓冲队列（供攻击动画结束时读取）
			if config["bufferable"]:
				buffer_input(action_name)
			action_triggered.emit(action_name)
			if DEBUG_MODE:
				print("[InputManager] action_triggered: ", action_name)
			return

## 功能：检测移动向量变化并发射信号
func _emit_movement_vector() -> void:
	if input_locked or _has_movement_block():
		if _last_movement != Vector2.ZERO:
			_last_movement = Vector2.ZERO
			movement_vector_changed.emit(Vector2.ZERO)
		return
	var vec: Vector2 = get_movement_vector()
	if vec != _last_movement:
		_last_movement = vec
		movement_vector_changed.emit(vec)

## 功能：检查指定的输入动作是否被前缀阻塞规则屏蔽
## 参数：action (String) - 动作名称
## 返回值：bool - true 表示该动作被屏蔽
func is_action_blocked(action: String) -> bool:
	return input_locked or _is_action_blocked(action)

## 功能：检查动作是否匹配阻塞前缀（内部使用）
## 参数：action (String) - 动作名称
## 返回值：bool - true 表示被阻塞
func _is_action_blocked(action: String) -> bool:
	for prefix in _blocked_action_prefixes:
		if action.begins_with(prefix):
			return true
	return false

## 功能：检查移动输入是否被阻塞
## 返回值：bool - true 表示移动输入应被屏蔽
func _has_movement_block() -> bool:
	for prefix in _blocked_action_prefixes:
		if "move" in prefix:
			return true
	return false

# ========================== 输入缓冲核心接口模块 ==========================
## 功能：将输入动作加入缓冲队列
## 说明：缓冲队列用于"输入排队"——玩家在攻击动画最后 150ms 内按下技能，
##       动画结束后自动读取并执行，避免因时机不对而丢失输入。
##       50ms 去重防止同一帧/连续帧重复入队。
## 参数：action (String) - 动作名称
## 返回值：bool - true 表示成功加入缓冲，false 表示失败
func buffer_input(action: String) -> bool:
	if input_locked:
		return false
	var config = INPUT_ACTIONS.get(action)
	if not config or not config["bufferable"]:
		return false

	var now_ms := Time.get_ticks_msec()
	# 50ms 去重：防止同一动作在短时间内重复入队
	if _buffer.size() > 0:
		var last: Dictionary = _buffer[-1]
		if last["action"] == action and (now_ms - last["time_ms"]) < 50:
			return false

	_buffer.append({ "action": action, "time_ms": now_ms })
	if DEBUG_MODE:
		print("[InputManager] 缓冲 + ", action, " 队列长度: ", _buffer.size())
	return true

## 功能：取出并返回最早未过期的缓冲输入
## 说明：由 PlayerAttackState 在攻击动画结束时调用，实现输入排队。
##       若队列为空或已锁定，返回空字符串表示无待执行动作。
## 返回值：String - 缓冲的动作名称，若无有效缓冲则返回空字符串
func get_buffered_input() -> String:
	_clean_expired_buffer()

	if _buffer.is_empty() or input_locked:
		return ""

	var entry: Dictionary = _buffer.pop_front()
	return entry["action"]

## 功能：清空缓冲队列（可选清空指定动作）
## 参数：action (String) - 若不为空则只清空该动作，否则清空全部
func clear_buffer(action: String = "") -> void:
	if action.is_empty():
		_buffer.clear()
	else:
		_buffer = _buffer.filter(func(e: Dictionary) -> bool: return e["action"] != action)

## 功能：清理过期的缓冲输入（超过 INPUT_BUFFER_DURATION_MS 毫秒）
## 说明：条目按时间顺序入队，缓冲时长仅 150ms，所有条目几乎同时过期，
##       因此只需检查首元素，过期则直接清空整个队列。
func _clean_expired_buffer() -> void:
	if _buffer.is_empty():
		return
	var now_ms := Time.get_ticks_msec()
	if now_ms - _buffer[0]["time_ms"] > INPUT_BUFFER_DURATION_MS:
		_buffer.clear()

# ========================== 输入状态查询接口模块 ==========================
## 功能：获取当前移动向量（归一化后）
## 返回值：Vector2 - 单位向量，范围 -1.0 到 1.0
func get_movement_vector() -> Vector2:
	if input_locked:
		return Vector2.ZERO
	var vec = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	return vec.limit_length(1.0)

## 功能：检查动作是否刚被按下（受输入锁定和前缀阻塞影响）
## 参数：action (String) - 动作名称
## 返回值：bool - true 表示刚被按下
func is_action_just_pressed(action: String) -> bool:
	return not input_locked and not _is_action_blocked(action) and Input.is_action_just_pressed(action)

## 功能：检查动作是否处于按住状态（受输入锁定和前缀阻塞影响）
## 参数：action (String) - 动作名称
## 返回值：bool - true 表示正在按住
func is_action_pressed(action: String) -> bool:
	return not input_locked and not _is_action_blocked(action) and Input.is_action_pressed(action)

## 功能：检查动作是否刚被释放（受输入锁定和前缀阻塞影响）
## 参数：action (String) - 动作名称
## 返回值：bool - true 表示刚被释放
func is_action_just_released(action: String) -> bool:
	return not input_locked and not _is_action_blocked(action) and Input.is_action_just_released(action)

# ========================== 输入锁定控制模块 ==========================
## 功能：设置输入锁定状态
## 参数：locked (bool) - true 锁定输入，false 解锁输入
func set_input_lock(locked: bool) -> void:
	if DEBUG_MODE:
		print("[InputManager] 当前输入状态 -> ", locked, "输入锁定状态 -> ", input_locked)
	if input_locked == locked:
		return
	input_locked = locked
	input_lock_changed.emit(locked)
	# 锁定时清空缓冲队列
	if locked:
		clear_buffer()

# ========================== 游戏状态回调模块 ==========================
## 功能：游戏状态变化时的回调，自动控制输入锁定
## 参数：new_state (GameManager.GameState) - 新游戏状态；_old_state (GameManager.GameState) - 旧状态
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.MAIN_MENU,\
		GameManager.GameState.SETTINGS,\
		GameManager.GameState.PAUSED,\
		GameManager.GameState.GAME_OVER:
			set_input_lock(true)
		GameManager.GameState.LOBBY,\
		GameManager.GameState.IN_GAME:
			set_input_lock(false)
		_:
			set_input_lock(false)

## 功能：更新输入阻塞前缀列表（由 UIManager 通过 EventBus 发出）
## 说明：匹配前缀的动作将被临时屏蔽，用于模态 UI 打开时阻止游戏输入穿透
## 参数：prefixes (Array[String]) - 需要阻塞的动作名前缀列表
func _on_input_blocking_updated(prefixes: Array[String]) -> void:
	_blocked_action_prefixes = prefixes

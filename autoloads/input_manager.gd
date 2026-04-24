# autoloads/input_manager.gd
# 全局输入管理器：管理输入映射、输入缓冲、按键状态跟踪
# 自动加载配置：Project -> Project Settings -> Autoloads 中添加，命名为 InputManager
extends Node

# TODO 当暂停时，所有按键都禁用了，但是有没有一种可能，就是暂停进入设置或其他界面时
# 还是需要使用到按键进行快捷操作，例如，使用方向键或Tab键进行组件选择，使用回车键进行确认

# ========================== 常量定义 ==========================
# 输入缓冲时长（毫秒）- 适配快节奏连招，可在balance_config中配置
const INPUT_BUFFER_DURATION_MS: int = 150   # 毫秒

# region 输入映射配置
# 输入映射配置
# 字段说明：
# - type: 输入类型（action/axis）
# - bufferable: 是否支持输入缓冲（战斗核心操作开启）
# - keyboard: 键鼠按键（主/备选）
# - priority: 输入优先级（1-5，5最高，用于冲突处理）
# - description: 功能描述（多语言适配预留）
# - category: 分类（movement/combat/ui/debug）
const INPUT_ACTIONS: Dictionary[String, Dictionary] = {
	# 移动类（Movement）
	"move_left": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["A", "Left Arrow"],
		"priority": 5,
		"description": "向左移动",
		"category": "movement"
	},
	"move_right": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["D", "Right Arrow"],
		"priority": 5,
		"description": "向右移动",
		"category": "movement"
	},
	"move_up": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["W", "Up Arrow"],
		"priority": 5,
		"description": "向上移动",
		"category": "movement"
	},
	"move_down": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["S", "Down Arrow"],
		"priority": 5,
		"description": "向下移动",
		"category": "movement"
	},
	"dash": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["Left Shift", "Right Mouse"],
		"priority": 4,
		"description": "瞬移冲刺（连招核心）",
		"category": "movement"
	},

	# 战斗核心类（Combat）
	"attack": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["Left Mouse", "C"],
		"priority": 3,
		"description": "普通攻击（连招起手）",
		"category": "combat"
	},
	"skill_1": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["1"],
		"priority": 3,
		"description": "技能1（起手型）",
		"category": "combat"
	},
	"skill_2": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["2"],
		"priority": 3,
		"description": "技能2（终结型）",
		"category": "combat"
	},
	"skill_3": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["3"],
		"priority": 3,
		"description": "技能3（控制型）",
		"category": "combat"
	},
	"skill_4": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["4"],
		"priority": 3,
		"description": "技能4（生存型）",
		"category": "combat"
	},
	"interact": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["F", "Space"],
		"priority": 2,
		"description": "交互（拾取/对话/开门）",
		"category": "combat"
	},

	# UI/系统类（UI/System）
	"pause": {
		"type": "action",
		"bufferable": false,
		"keyboard": ["Escape", "P"],
		"priority": 1,
		"description": "暂停游戏/打开菜单",
		"category": "ui"
	},
	"ui_confirm_q": {
		"type": "action",
		"bufferable": false,
		"keyboard": ["Q", "Enter"],
		"priority": 1,
		"description": "UI确认",
		"category": "ui"
	},
	"ui_cancel_e": {
		"type": "action",
		"bufferable": false,
		"keyboard": ["E", "Backspace"],
		"priority": 1,
		"description": "UI取消/返回",
		"category": "ui"
	}
}
# endregion

# ========================== 变量定义 ==========================
# 是否锁定输入（暂停/菜单时禁用）
var input_locked: bool = false
# 输入缓冲队列: Array[Dictionary{action: String, time_ms: int}]
var _buffer: Array[Dictionary] = []

# ========================== 信号定义 ==========================
# 输入缓冲触发（当缓冲的输入被处理时）
signal buffered_input_triggered(action: String)
# 输入锁定状态变更
signal input_lock_changed(is_locked: bool)
# 核心战斗输入触发（简化战斗系统监听）
signal combat_input_triggered(action: String, is_buffered: bool)

# ========================== 初始化 ==========================
func _ready() -> void:
	_connect_game_state()
	print("InputManager: 输入管理器初始化完成")
	
func _connect_game_state() -> void:
	if GameManager and GameManager.has_signal("game_state_changed"):
		GameManager.game_state_changed.connect(_on_game_state_changed)
		# 兜底：信号已发出但未收到时，手动同步一次
		_on_game_state_changed(GameManager.current_game_state, GameManager.GameState.NULL)
		
# ========================== 输入状态更新 ==========================
func _process(_delta: float) -> void:
	if input_locked:
		return
	# 处理暂停键（即时响应）
	if Input.is_action_just_pressed("pause"):
		UIManager.open_pause_menu()

# ========================== 输入缓冲核心接口 ==========================
func buffer_input(action: String) -> bool:
	"""
	缓冲输入动作
	参数: action - 输入动作名（需在INPUT_ACTIONS中定义）
	返回: 是否成功缓冲
	"""
	if input_locked:
		return false
	var config = INPUT_ACTIONS.get(action)
	if not config or not config["bufferable"]:
		return false
		
	# 避免重复缓冲同一动作（短时间内）
	# 防重复：如果队列最后一个动作相同且时间差<50ms，忽略
	var now_ms = Time.get_ticks_msec()
	if _buffer.size() > 0:
		var last = _buffer[-1]
		if last["action"] == action and (now_ms - last["time_ms"]) < 50:
			return false

	_buffer.append({ "action": action, "time_ms": now_ms })
	if Global.DEBUG_MODE:
		print("[InputManager] 缓冲 + ", action, " 队列长度: ", _buffer.size())

	return true

func get_buffered_input() -> String:
	"""
	获取并移除首个有效缓冲输入
	返回: 缓冲的动作名（无则返回空字符串）
	"""
	_clean_expired_buffer()
	
	if _buffer.is_empty() or input_locked:
		return ""
	
	var entry = _buffer.pop_front()
	buffered_input_triggered.emit(entry.action)
	combat_input_triggered.emit(entry.action, true)
	return entry.action

func clear_buffer(action: String = "") -> void:
	"""
	清空输入缓冲
	参数: action - 可选，指定清空某个动作的缓冲（为空则清空全部）
	"""
	if action.is_empty():
		_buffer.clear()
	else:
		_buffer = _buffer.filter(func(e): return e.action != action)
	if Global.DEBUG_MODE:
		print("[InputManager] 清空缓冲 -> ", action if action != "" else "全部")

func _clean_expired_buffer() -> void:
	"""清理超时的输入缓冲s"""
	var now_ms = Time.get_ticks_msec()
	var i = 0
	while i < _buffer.size():
		if now_ms - _buffer[i]["time_ms"] > INPUT_BUFFER_DURATION_MS:
			_buffer.remove_at(i)
		else:
			i += 1
	
# ========================== 输入状态查询接口 ==========================
func get_movement_vector() -> Vector2:
	"""
	获取规范化的移动向量
	返回: 二维移动向量（-1~1）
	"""
	if input_locked:
		return Vector2.ZERO
	var vec = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	return vec.limit_length(1.0)
	
func is_action_just_pressed(action: String) -> bool:
	"""安全查询按键刚按下状态（输入锁定时返回false）"""
	return not input_locked and Input.is_action_just_pressed(action)

func is_action_pressed(action: String) -> bool:
	"""安全查询按键长按状态（输入锁定时返回false）"""
	return not input_locked and Input.is_action_pressed(action)

func is_action_just_released(action: String) -> bool:
	"""安全查询按键刚松开状态（输入锁定时返回false）"""
	return not input_locked and Input.is_action_just_released(action)

# ========================== 输入锁定控制 ==========================
func set_input_lock(locked: bool) -> void:
	"""设置输入锁定状态"""
	if input_locked == locked:
		return
	input_locked = locked
	input_lock_changed.emit(locked)
	# 锁定时清空缓冲
	if locked:
		clear_buffer()
	if Global.DEBUG_MODE:
		print("[InputManager] 输入锁定状态 -> ", locked)

# ========================== 游戏状态回调 ==========================
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	"""监听游戏状态变更，自动控制输入锁定"""
	match new_state:
		GameManager.GameState.MAIN_MENU,\
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
	"""调试模式：打印所有按下的按键（非锁定时）"""
	if not Global.DEBUG_MODE or input_locked:
		return
	
	# 只打印按下事件（忽略重复的自动连发事件）
	if event.is_pressed() and not event.is_echo():
		for action in INPUT_ACTIONS:
			if InputMap.event_is_action(event, action):
				print("[InputManager] 按键: %s 动作触发: %s" % [event.as_text(), action])
				break  # 一个事件可能匹配多个动作，但通常只需打印一个

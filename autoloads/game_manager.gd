# autoloads/game_manager.gd
# 游戏状态管理器：管理游戏状态（菜单/游戏中/暂停/设置）
# 自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 GameManager
extends Node

# ========================== 全局信号 ==========================
# 游戏状态变更（参数：新状态、旧状态）
signal game_state_changed(new_state: GameState, old_state: GameState)

# ========================== 核心枚举 ==========================
# 游戏全局状态
enum GameState {
	MAIN_MENU,       # 主菜单
	IN_GAME,         # 游戏中
	PAUSED,          # 暂停
	SETTINGS,        # 设置界面
	GAME_OVER,       # 游戏结束
	NULL
}

# ========================== 全局变量 ==========================
# 当前游戏状态
var current_game_state: GameState = GameState.NULL
# 状态历史栈（用于 safe_push_state / pop_state）
var _state_stack: Array[GameState] = []

# ========================== 工具函数 ==========================
# 切换游戏状态（触发game_state_changed信号）
func set_game_state(new_state: GameState) -> void:
	if new_state == current_game_state:
		return
	var old_state: GameState = current_game_state
	current_game_state = new_state
	
	game_state_changed.emit(new_state, old_state)
	print("[GameManager] 游戏状态变更 -> ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])

# ========================== 生命周期 ==========================
func _ready() -> void:
	# 初始化游戏状态为主菜单
	set_game_state(GameState.MAIN_MENU)
	print("GameManager: 游戏状态管理器初始化完成")

func _process(_delta: float) -> void:
	# 调试：按F11快速切换游戏状态（仅调试模式）
	if Input.is_action_just_pressed("debug_toggle_game_state"):
		var next_state: int = (current_game_state + 1) % GameState.values().size()
		set_game_state(next_state)

# ========================== 状态栈操作（推荐用于打开/关闭临时界面） ==========================
func push_state(new_state: GameState) -> void:
	"""临时切换到新状态，自动保存当前状态到栈"""
	_state_stack.append(current_game_state)
	set_game_state(new_state)

func pop_state() -> void:
	"""恢复到上一个状态（栈顶）"""
	if _state_stack.is_empty():
		print("[GameManager] 状态栈为空，无法 pop_state")
		return
	var previous_state = _state_stack.pop_back()
	set_game_state(previous_state)

func clear_state_stack() -> void:
	"""清空状态栈（通常在返回主菜单等全局重置时使用）"""
	_state_stack.clear()

func reset_to_main_menu() -> void:
	"""清空状态栈的时机(彻底返回主菜单或重新开始游戏)"""
	clear_state_stack()          # 清空状态栈
	set_game_state(GameState.MAIN_MENU)

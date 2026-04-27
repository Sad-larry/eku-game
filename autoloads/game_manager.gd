# autoloads/game_manager.gd
# 游戏状态管理器：管理游戏状态
# 自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 GameManager
extends Node

# ========================== 全局信号 ==========================
# 游戏状态变更（参数：新状态、旧状态）
signal game_state_changed(new_state: GameState, old_state: GameState)

# ========================== 核心枚举 ==========================
# 游戏全局状态
## 主菜单:MAIN_MENU;游戏大厅:LOBBY;游戏中:IN_GAME;暂停:PAUSED;设置界面:SETTINGS;游戏结束:GAME_OVER;UNINITIALIZED
enum GameState {
	MAIN_MENU,       # 主菜单
	LOBBY,           # 游戏大厅
	IN_GAME,         # 游戏中
	PAUSED,          # 暂停
	SETTINGS,        # 设置界面
	GAME_OVER,       # 游戏结束
	UNINITIALIZED
}

# ========================== 常量 ==========================
# 调试开关
const DEBUG_MODE: bool = true

# ========================== 全局变量 ==========================
# 当前游戏状态
var current_game_state: GameState = GameState.UNINITIALIZED
# 状态历史栈（用于 safe_push_state / pop_state）
var _state_stack: Array[GameState] = []

# ========================== 生命周期 ==========================
func _ready() -> void:
	# 初始化游戏状态为主菜单
	set_game_state(GameState.MAIN_MENU)
	print("GameManager: 游戏状态管理器初始化完成")

func _process(_delta: float) -> void:
	# 调试：按F11快速切换游戏状态（仅调试模式）
	if DEBUG_MODE and Input.is_action_just_pressed("debug_toggle_game_state"):
		var next_state: int = (current_game_state + 1) % GameState.values().size()
		set_game_state(next_state)
		print("[GameManager] 调试 - 游戏状态：", GameState.keys()[current_game_state])


# ========================== 工具函数 ==========================
# 切换游戏状态（触发game_state_changed信号）
## @param new_state: 目标游戏状态（来自 GameState 枚举）
func set_game_state(new_state: GameState) -> void:
	if new_state == current_game_state:
		return
	
	var old_state: GameState = current_game_state
	current_game_state = new_state
	
	game_state_changed.emit(new_state, old_state)
	print("[GameManager] 游戏状态变更 -> ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])

# ========================== 状态栈操作（推荐用于打开/关闭临时界面） ==========================
## 临时切换到新状态，自动保存当前状态到栈
## 适用于打开设置、暂停菜单等需要临时覆盖状态的场景
## @param new_state: 要进入的新状态（不能与当前状态相同，否则会忽略并打印警告）
func push_state(new_state: GameState) -> void:
	if new_state == current_game_state:
		if DEBUG_MODE:
			print("[GameManager] push_state 警告: 试图推入与当前状态相同的状态 (", GameState.keys()[new_state], ")，已忽略")
		return
	_state_stack.append(current_game_state)
	set_game_state(new_state)

## 恢复到上一个状态（栈顶）
## 通常在关闭临时界面时调用，会自动恢复之前保存的状态
func pop_state() -> void:
	if _state_stack.is_empty():
		if DEBUG_MODE:
			print("[GameManager] pop_state 错误: 状态栈为空，无法弹出")
		return
	var previous_state = _state_stack.pop_back()
	set_game_state(previous_state)

## 清空状态栈（通常在返回主菜单等全局重置时使用）
func clear_state_stack() -> void:
	_state_stack.clear()
	if DEBUG_MODE:
		print("[GameManager] 状态栈已清空")

## 彻底返回主菜单，清空状态栈并设置状态为 MAIN_MENU
func reset_to_main_menu() -> void:
	clear_state_stack()
	set_game_state(GameState.MAIN_MENU)

# ==============================================================================
#   game_manager.gd
#   功能：游戏状态管理器（Autoload 单例），负责管理游戏的全局状态（主菜单、游戏中、暂停等），
#        提供状态切换、状态栈操作（临时界面如设置/暂停菜单的打开与关闭）、状态变更信号。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 GameManager
# ==============================================================================
extends Node

# ========================== 枚举定义模块 ==========================
## 游戏全局状态枚举
## MAIN_MENU、LOBBY、IN_GAME、PAUSED、SETTINGS、GAME_OVER、UNINITIALIZED
enum GameState {
	MAIN_MENU,       ## 主菜单界面
	LOBBY,           ## 游戏大厅/房间界面
	IN_GAME,         ## 游戏中（核心玩法进行中）
	PAUSED,          ## 游戏暂停状态
	SETTINGS,        ## 设置界面（作为临时覆盖层）
	GAME_OVER,       ## 游戏结束状态
	UNINITIALIZED    ## 未初始化状态（初始占位）
}

# ========================== 信号声明模块 ==========================
## 触发时机：游戏全局状态发生变更时
## 参数：new_state (GameState) - 新状态，old_state (GameState) - 旧状态
signal game_state_changed(new_state: GameState, old_state: GameState)

# ========================== 常量定义模块 ==========================
## 调试模式开关（开启后支持 F11 快捷键切换游戏状态用于测试）
const DEBUG_MODE: bool = true

# ========================== 变量定义模块 ==========================
## 当前游戏全局状态（初始为 UNINITIALIZED）
var current_game_state: GameState = GameState.UNINITIALIZED
## 状态历史栈（用于 push_state / pop_state 操作，支持临时界面覆盖）
var _state_stack: Array[GameState] = []

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时完成初始化并设置初始状态为主菜单
func _ready() -> void:
	# 通过 EventBus 监听来自 UIManager 的状态推入/弹出请求
	EventBus.game_state_push_requested.connect(push_state)
	EventBus.game_state_pop_requested.connect(pop_state)
	# 初始化游戏状态为主菜单
	set_game_state(GameState.MAIN_MENU)
	print("GameManager: 游戏状态管理器初始化完成")

# ========================== 公共 API 模块 ==========================
## 功能：切换游戏状态（触发 game_state_changed 信号）
## 参数：new_state (GameState) - 目标游戏状态
## 说明：若目标状态与当前状态相同，则不执行任何操作
func set_game_state(new_state: GameState) -> void:
	if new_state == current_game_state:
		return

	var old_state: GameState = current_game_state
	current_game_state = new_state

	game_state_changed.emit(new_state, old_state)
	print("[GameManager] 游戏状态变更 -> ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])

# ========================== 状态栈操作模块 ==========================
## 功能：临时切换到新状态，自动保存当前状态到栈（适用于打开设置、暂停菜单等需要临时覆盖状态的场景）
## 参数：new_state (GameState) - 要进入的新状态
## 说明：若新状态与当前状态相同，会忽略并打印警告（仅在调试模式下输出）
func push_state(new_state: GameState) -> void:
	if new_state == current_game_state:
		if DEBUG_MODE:
			print("[GameManager] push_state 警告: 试图推入与当前状态相同的状态 (", GameState.keys()[new_state], ")，已忽略")
		return
	_state_stack.append(current_game_state)
	set_game_state(new_state)

## 功能：恢复到上一个状态（弹出栈顶）
## 说明：通常在关闭临时界面时调用，自动恢复之前保存的状态；若状态栈为空则忽略
func pop_state() -> void:
	if _state_stack.is_empty():
		if DEBUG_MODE:
			print("[GameManager] pop_state 错误: 状态栈为空，无法弹出")
		return
	var previous_state = _state_stack.pop_back()
	set_game_state(previous_state)

## 功能：清空状态栈（通常在返回主菜单等全局重置时使用）
func clear_state_stack() -> void:
	_state_stack.clear()
	if DEBUG_MODE:
		print("[GameManager] 状态栈已清空")

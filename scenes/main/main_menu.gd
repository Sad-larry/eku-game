# ==============================================================================
#   main_menu.gd
#   功能：主菜单界面控制器，负责游戏状态切换、开始游戏/设置/退出按钮响应、
#        场景加载转场。包含待完善的动画转场逻辑。
# ==============================================================================
extends Control
class_name MainMenu

# ========================== 节点引用模块 ==========================
## 画布层节点引用（用于可能的动画转场）
@onready var canvas_layer: CanvasLayer = $CanvasLayer

# ========================== 变量定义模块 ==========================
## 是否正在加载场景的标记（防止重复加载）
var is_loading := false

# ========================== TODO 待完善事项 ==========================
# TODO: 可以选用画布下拉动画进行初始游戏界面，比如在主菜单界面和游戏界面之间加入画布下拉动画，
#       动画背景为初始游戏界面画面，实现无缝转场，而不是用定时器。

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时设置游戏状态为主菜单
func _ready() -> void:
	GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
	print("MainMenu: 主菜单初始化完成")

## 功能：测试用 _process 逻辑（当前为自动触发场景加载的测试代码）
## 参数：_delta (float) - 帧间隔时间（未使用）
## 说明：此处的测试代码会立即自动加载游戏场景，实际项目中应移除或根据需求调整。
func _process(_delta: float) -> void:
	# 测试代码：自动加载游戏场景（仅执行一次）
	if not is_loading and Global.DEBUG_MODE:
		_load_game_scene()
		is_loading = true

# ========================== UI 按钮事件模块 ==========================
## 功能：开始游戏按钮被按下时的回调
## 说明：开始游戏过渡（当前直接调用 _load_game_scene 加载场景）
func _on_start_button_pressed() -> void:
	# TODO: 可在此处添加过渡动画，延迟加载场景以适配动画时长
	_load_game_scene()

## 功能：设置按钮被按下时的回调
## 说明：打开设置菜单（委托给 UIManager）
func _on_settings_button_pressed() -> void:
	UIManager.open_settings_menu()

## 功能：退出游戏按钮被按下时的回调
## 说明：保存存档后退出游戏
func _on_quit_button_pressed() -> void:
	SaveManager.save_immediately()
	get_tree().quit()

# ========================== 场景加载模块 ==========================
## 功能：加载游戏大厅场景并更新游戏状态
## 说明：通过 SceneLoader 执行淡入淡出转场，加载完成后将游戏状态设置为 LOBBY
func _load_game_scene() -> void:
	# 加载游戏场景（替换当前场景）
	await SceneLoader.change_scene(Global.GAME_LOBBY_SCENE_PATH)
	GameManager.set_game_state(GameManager.GameState.LOBBY)

# scenes/main/main_menu.gd
# 主菜单逻辑：开始游戏跳转、输入锁定/解锁、动画控制
extends Control
class_name MainMenu

# ========================== 依赖引用 ==========================
@onready var canvas_layer: CanvasLayer = $CanvasLayer

# ========================== 变量 ==========================
var is_loading := false
# ========================== 初始化和销毁 ==========================
func _ready() -> void:
	GameManager.set_game_state(GameManager.GameState.MAIN_MENU)
	print("MainMenu: 主菜单初始化完成")
	

func _process(_delta: float) -> void:
	# test
	if not is_loading:
		_load_game_scene()
		is_loading = true
	
# ========================== 按钮事件 ==========================
func _on_start_button_pressed() -> void:
	"""开始游戏：锁定输入 → 播放过渡动画 → 加载游戏场景"""
	# 延迟加载场景（适配动画时长）
	# TODO 可以选用画布下拉动画进行初始游戏界面，比如在主菜单界面和游戏界面之间加入画布下拉动画
	# 动画背景为初始游戏界面画面，实现无缝转场，而不是用定时器
	#await get_tree().create_timer(0.3).timeout
	_load_game_scene()
	
func _on_settings_button_pressed() -> void:
	"""打开设置菜单（预留逻辑）"""
	UIManager.open_settings_menu()
	
func _on_quit_button_pressed() -> void:
	"""退出游戏"""
	# TODO 应该也用GameManager来更新游戏状态，改为QUIT状态
	# 在QUIT状态下需要保存游戏数据，然后再销毁
	get_tree().quit()
	
# ========================== 场景加载 ==========================
func _load_game_scene() -> void:
	"""加载游戏主城场景，更新游戏状态"""
	# 加载游戏场景（替换当前场景）
	await SceneLoader.change_scene(Global.GAME_LOBBY_SCENE_PATH)
	GameManager.set_game_state(GameManager.GameState.IN_GAME)

# ==============================================================================
#   pause_menu.gd
#   功能：暂停菜单界面控制器，提供继续游戏、打开设置、返回主菜单、退出游戏等按钮功能。
# ==============================================================================
extends Control
class_name PauseMenu

# ========================== 节点引用模块 ==========================
## 继续游戏按钮（需在场景中通过 %ContinueBtn 唯一命名）
@onready var continue_btn: Button = %ContinueBtn

## 设置按钮（需在场景中通过 %SettingsBtn 唯一命名）
@onready var settings_btn: Button = %SettingsBtn

## 返回主菜单按钮（需在场景中通过 %BackToMenuBtn 唯一命名）
@onready var back_to_menu_btn: Button = %BackToMenuBtn

## 退出游戏按钮（需在场景中通过 %QuitBtn 唯一命名）
@onready var quit_btn: Button = %QuitBtn

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# 暂停后 InputManager 的 _process() 不再运行，无法再检测暂停键
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		UIManager.close_pause_menu()

# ========================== UI 按钮事件模块 ==========================
## 功能：继续游戏按钮被按下时，关闭暂停菜单
func _on_continue_btn_pressed() -> void:
	UIManager.close_pause_menu()
	
## 功能：返回游戏大厅（运行中时保存检查点）
func _on_lobby_btn_pressed() -> void:
	UIManager.close_pause_menu()
	# 如果运行进行中，暂停运行并保存检查点
	if RunManager.is_run_active():
		RunManager.pause_run()
	SceneLoader.change_scene(Global.GAME_LOBBY_SCENE_PATH)

## 功能：设置按钮被按下时，打开设置菜单（由 UIManager 管理）
func _on_settings_btn_pressed() -> void:
	UIManager.open_settings_menu()

## 功能：返回主菜单按钮被按下时，保存存档后通过 EventBus 通知各管理器清空各自数据并切换场景
func _on_back_to_menu_btn_pressed() -> void:
	SaveManager.save_immediately()
	EventBus.return_to_main_menu_requested.emit()
	get_tree().change_scene_to_file(Global.MAIN_MENU_SCENE_PATH)

## 功能：退出游戏按钮被按下时，保存存档后通过 EventBus 通知各管理器清空各自数据后退出
func _on_quit_btn_pressed() -> void:
	SaveManager.save_immediately()
	EventBus.return_to_main_menu_requested.emit()
	get_tree().quit()

# scenes/ui/pause_menu.gd
extends Control
class_name PauseMenu

# 自动获取节点
@onready var continue_btn: Button = %ContinueBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var back_to_menu_btn: Button = %BackToMenuBtn
@onready var quit_btn: Button = %QuitBtn

# 继续游戏
func _on_continue_btn_pressed() -> void:
	UIManager.close_pause_menu()

# 打开设置
func _on_settings_btn_pressed() -> void:
	UIManager.open_settings_menu()

# 返回主菜单
func _on_back_to_menu_btn_pressed() -> void:
	UIManager.close_pause_menu()
	get_tree().change_scene_to_file(Global.START_MENU_SCENE_PATH)

# 退出游戏
func _on_quit_btn_pressed() -> void:
	get_tree().quit()

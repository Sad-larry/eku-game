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

# ========================== UI 按钮事件模块 ==========================
## 功能：继续游戏按钮被按下时，关闭暂停菜单
func _on_continue_btn_pressed() -> void:
	UIManager.close_pause_menu()

## 功能：设置按钮被按下时，打开设置菜单（由 UIManager 管理）
func _on_settings_btn_pressed() -> void:
	UIManager.open_settings_menu()

## 功能：返回主菜单按钮被按下时，关闭暂停菜单并切换场景到主菜单
func _on_back_to_menu_btn_pressed() -> void:
	UIManager.close_pause_menu()
	get_tree().change_scene_to_file(Global.MAIN_MENU_SCENE_PATH)

## 功能：退出游戏按钮被按下时，退出应用程序
func _on_quit_btn_pressed() -> void:
	get_tree().quit()

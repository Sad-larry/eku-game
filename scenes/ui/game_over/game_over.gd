# ==============================================================================
#   GameOver.gd
#   功能：游戏结束界面控制器，处理返回按钮点击事件，关闭当前界面、切换场景
#        并恢复游戏状态为游戏中。
# ==============================================================================
extends Control
class_name GameOver

# ========================== 节点引用模块 ==========================
## 返回按钮节点（需在场景中通过 %BackButton 唯一命名）
@onready var back_button: Button = %BackButton

# ========================== 信号回调模块 ==========================
## 功能：返回按钮被点击时触发的回调
## 说明：关闭游戏结束界面 -> 切换场景至游戏大厅 -> 将游戏状态设置为游戏中
func _on_back_button_pressed() -> void:
	UIManager.close_game_over()
	await SceneLoader.change_scene(Global.GAME_LOBBY_SCENE_PATH)
	GameManager.set_game_state(GameManager.GameState.LOBBY)

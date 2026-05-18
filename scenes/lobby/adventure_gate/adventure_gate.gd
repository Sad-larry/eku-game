# ==============================================================================
#   adventure_gate.gd
#   功能：冒险大门（传送门），玩家进入后切换到游戏世界场景。
#        若有中断的运行，弹出对话框询问继续还是新冒险。
# ==============================================================================
extends Node2D
class_name AdventureGate

# ========================== 变量定义模块 ==========================
## 对话框是否已打开（防止 body_entered 重复触发）
var _is_dialog_open: bool = false

# ========================== 信号回调模块 ==========================
## 功能：传送门身体进入检测回调，进入冒险
func _on_portal_to_adventure_body_entered(body: Node2D) -> void:
	if not (body is Player) or _is_dialog_open:
		return

	# 检查是否有中断的运行
	if RunManager.has_interrupted_run():
		_show_continue_dialog(body)
	else:
		_start_new_adventure()

## 功能：显示继续冒险确认对话框
func _show_continue_dialog(player_body: Player) -> void:
	_is_dialog_open = true
	player_body.disable_movement()

	var dialog := ConfirmationDialog.new()
	dialog.title = "冒险继续"
	dialog.dialog_text = "检测到未完成的冒险，是否继续？"
	dialog.ok_button_text = "继续冒险"
	dialog.cancel_button_text = "开始新冒险"
	dialog.exclusive = true
	add_child(dialog)
	dialog.popup_centered()

	# 继续冒险
	dialog.confirmed.connect(func():
		_is_dialog_open = false
		if is_instance_valid(player_body):
			player_body.enable_movement()
		RunManager.resume_run()
		SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)
	)

	# 开始新冒险（取消按钮）
	dialog.canceled.connect(func():
		_is_dialog_open = false
		if is_instance_valid(player_body):
			player_body.enable_movement()
		RunManager.cleanup_run_state()
		_start_new_adventure()
	)

	dialog.close_requested.connect(func():
		_is_dialog_open = false
		if is_instance_valid(player_body):
			player_body.enable_movement()
	)

## 功能：开始新冒险
func _start_new_adventure() -> void:
	RunManager.start_new_run()
	SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)

# ==============================================================================
#   game_over.gd
#   功能：游戏结束界面控制器，显示运行统计、继续冒险按钮和返回大厅按钮。
#        根据 RunManager 状态决定是否显示"继续冒险"选项。
# ==============================================================================
extends Control
class_name GameOver

# ========================== 节点引用模块 ==========================
@onready var back_button: Button = %BackButton
@onready var continue_button: Button = %ContinueButton
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var title_label: Label = %TitleLabel

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_setup_ui()

# ========================== 初始化模块 ==========================
func _setup_ui() -> void:
	# 根据运行状态设置标题
	var is_death: bool = RunManager.run_status == RunManager.RunStatus.FAILED
	if title_label:
		title_label.text = "冒险失败" if is_death else "游戏结束"

	# 显示/隐藏继续冒险按钮
	if continue_button:
		var has_checkpoint: bool = RunManager.has_interrupted_run()
		continue_button.visible = has_checkpoint
		continue_button.pressed.connect(_on_continue_button_pressed)

	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

	# 显示运行统计
	_update_stats_display()

func _update_stats_display() -> void:
	if stats_container == null:
		return
	var stats: Dictionary = RunManager.get_run_stats()
	var elapsed: float = RunManager.run_elapsed_time

	# 清除旧内容
	for child in stats_container.get_children():
		child.queue_free()

	var lines: Array[String] = []
	lines.append("层数: %d" % RunManager.current_layer)
	lines.append("房间清除: %d" % stats.get("rooms_cleared", 0))
	lines.append("击杀敌人: %d" % stats.get("enemies_killed", 0))
	lines.append("累计伤害: %d" % stats.get("total_damage_dealt", 0))
	lines.append("金币获取: %d" % stats.get("coins_collected", 0))

	var minutes: int = int(elapsed) / 60
	var seconds: int = int(elapsed) % 60
	lines.append("用时: %02d:%02d" % [minutes, seconds])

	for line in lines:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		stats_container.add_child(label)

# ========================== 信号回调模块 ==========================
func _on_back_button_pressed() -> void:
	# 结束运行并返回大厅
	if RunManager.is_run_active():
		RunManager.end_run(RunManager.RunStatus.FAILED, "death")
	RunManager.cleanup_run_state()
	UIManager.close_game_over()
	SaveManager.save_immediately()
	await SceneLoader.change_scene(Global.GAME_LOBBY_SCENE_PATH)
	GameManager.set_game_state(GameManager.GameState.LOBBY)

func _on_continue_button_pressed() -> void:
	# 从检查点恢复继续冒险
	UIManager.close_game_over()
	var checkpoint_data: Dictionary = RunManager.restore_from_checkpoint()
	var world_seed: int = checkpoint_data.get("world_seed", 0)
	var current_layer: int = checkpoint_data.get("current_layer", 1)

	RunManager.start_new_run(world_seed)
	RunManager.current_layer = current_layer
	await SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)

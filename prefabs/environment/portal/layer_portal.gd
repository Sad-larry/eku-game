# ==============================================================================
#   layer_portal.gd
#   功能：层间传送门，Boss 击败后出现。
#        玩家交互后推进层数并重新生成地图。
# ==============================================================================
extends Node2D
class_name LayerPortal

# ========================== 节点引用模块 ==========================
@onready var portal_area: Area2D = $PortalArea
@onready var visual: Node2D = $Visual

# ========================== 变量定义模块 ==========================
var _is_dialog_open: bool = false

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	if portal_area:
		portal_area.body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if visual:
		# 旋转 + 呼吸灯效果
		var t := Time.get_ticks_msec() * 0.001
		visual.rotation += _delta * 0.5
		visual.modulate.a = 0.6 + 0.3 * sin(t * 2.0)

# ========================== 交互模块 ==========================
func _on_body_entered(body: Node2D) -> void:
	if not (body is Player) or _is_dialog_open:
		return
	_show_advance_dialog(body)

func _show_advance_dialog(player_body: Player) -> void:
	_is_dialog_open = true
	player_body.disable_movement()

	var next_layer := RunManager.current_layer + 1
	var dialog := ConfirmationDialog.new()
	dialog.title = "传送门"
	dialog.dialog_text = "即将进入第 %d 层\n难度将会提升，准备好了吗？" % next_layer
	dialog.ok_button_text = "出发"
	dialog.cancel_button_text = "再等等"
	dialog.exclusive = true
	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		_is_dialog_open = false
		if is_instance_valid(player_body):
			player_body.enable_movement()
		_advance_to_next_layer()
	)

	dialog.canceled.connect(func():
		_is_dialog_open = false
		if is_instance_valid(player_body):
			player_body.enable_movement()
	)

	dialog.close_requested.connect(func():
		_is_dialog_open = false
		if is_instance_valid(player_body):
			player_body.enable_movement()
	)

func _advance_to_next_layer() -> void:
	RunManager.advance_layer()
	SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)

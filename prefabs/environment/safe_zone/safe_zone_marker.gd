# ==============================================================================
#   safe_zone_marker.gd
#   功能：安全区标记组件，放置在 ring=0 的 start 房间中。
#        提供出生点光圈和返回大厅传送门。
# ==============================================================================
extends Node2D
class_name SafeZoneMarker

# ========================== 信号声明模块 ==========================
## 触发时机：玩家请求返回大厅
signal player_wants_to_leave()

# ========================== 导出变量模块 ==========================
## 是否包含返回大厅的传送门
@export var portal_enabled: bool = true

# ========================== 节点引用模块 ==========================
## 出生点光圈（视觉标记）
@onready var spawn_circle: Node2D = $SpawnCircle
## 返回大厅传送门区域
@onready var portal_area: Area2D = $PortalArea

# ========================== 变量定义模块 ==========================
## 对话框是否已打开（防止重复触发）
var _is_dialog_open: bool = false

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	if portal_area:
		portal_area.body_entered.connect(_on_portal_body_entered)
		portal_area.visible = portal_enabled
		portal_area.monitoring = portal_enabled

## 功能：每帧更新出生点光圈动画
func _process(_delta: float) -> void:
	if spawn_circle:
		# 简单的呼吸灯效果
		var t := Time.get_ticks_msec() * 0.002
		var alpha := 0.3 + 0.2 * sin(t)
		spawn_circle.modulate.a = alpha

# ========================== 传送门交互模块 ==========================
## 功能：玩家进入传送门区域时触发
func _on_portal_body_entered(body: Node2D) -> void:
	if not (body is Player) or _is_dialog_open or not portal_enabled:
		return
	_show_leave_dialog(body)

## 功能：显示返回大厅确认对话框
func _show_leave_dialog(player_body: Player) -> void:
	_is_dialog_open = true
	player_body.disable_movement()

	var dialog := ConfirmationDialog.new()
	dialog.title = "返回大厅"
	dialog.dialog_text = "确定要返回大厅吗？\n当前冒险进度将被保存。"
	dialog.ok_button_text = "返回大厅"
	dialog.cancel_button_text = "继续冒险"
	dialog.exclusive = true
	add_child(dialog)
	dialog.popup_centered()

	# 确认返回大厅
	dialog.confirmed.connect(func():
		_is_dialog_open = false
		if is_instance_valid(player_body):
			player_body.enable_movement()
		player_wants_to_leave.emit()
		# 暂停运行并保存检查点
		if RunManager.is_run_active():
			RunManager.pause_run()
		SceneLoader.change_scene(Global.GAME_LOBBY_SCENE_PATH)
	)

	# 取消
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

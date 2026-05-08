# ==============================================================================
#   LobbyWorld.gd
#   功能：游戏大厅场景控制器，管理玩家出生点设置、游戏状态切换，
#        并提供传送门触发逻辑（切换到冒险关卡）。
# ==============================================================================
extends Node2D
class_name LobbyWorld

# ========================== TODO 待修改事项 ==========================
# TODO: LobbyWorld 中的 RoomBase 后续需要替换掉，因为这个是冒险地图专用的房间基类
#       LobbyWorld 不需要被 RoomManager 所管理（当前未使用 RoomBase，仅保留注释说明）

# ========================== 节点引用模块 ==========================
## 玩家出生点标记（需要在场景中设置 %PlayerSpawn 唯一命名）
@onready var player_spawn: Marker2D = %PlayerSpawn

## 全局玩家对象引用（由 Global 单例提供）
@onready var player: Player = Global.player

# ========================== 变量定义模块 ==========================
## 传送门对话框是否已打开（防止 body_entered 重复触发）
var _is_portal_dialog_open: bool = false

# ========================== 生命周期模块 ==========================
## 功能：大厅场景就绪时，将玩家放置到出生点并设置游戏状态为大厅
func _ready() -> void:
	# 将玩家位置设置为出生点坐标
	if player and player_spawn:
		player.global_position = player_spawn.global_position
	
	# 设置游戏状态为大厅（确保 HUD 等系统正确响应）
	GameManager.set_game_state(GameManager.GameState.LOBBY)
	print("LobbyWorld: 大厅初始化完成")
	
# ========================== 内部函数模块 ==========================
## 恢复玩家移动并清理对话框
func _restore_player_movement(player_obj: Player, dialog: ConfirmationDialog) -> void:
	_is_portal_dialog_open = false

	if is_instance_valid(player_obj):
		player_obj.enable_movement()

	if is_instance_valid(dialog):
		dialog.queue_free()
		
# ========================== 信号回调模块 ==========================
## 功能：传送门的身体进入检测回调，用于切换到冒险关卡
## 参数：body (Node2D) - 进入传送门的实体（通常为玩家）
func _on_portal_to_dungeon_body_entered(body: Node2D) -> void:
	if true:
		SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)
		return
	if not (body is Player) or _is_portal_dialog_open:
		return
	
	_is_portal_dialog_open = true

	# 停止玩家移动并锁定输入
	body.disable_movement()

	# 创建确认对话框
	var dialog := ConfirmationDialog.new()
	dialog.title = "进入挑战"
	dialog.dialog_text = "确定要进入挑战吗？"
	dialog.ok_button_text = "确认"
	dialog.cancel_button_text = "取消"
	dialog.exclusive = true

	add_child(dialog)
	dialog.popup_centered()

	# 确认 -> 进入关卡
	dialog.confirmed.connect(func():
		# 通过 SceneLoader 执行淡入淡出场景切换
		# TODO: 后续可根据实际关卡 ID 动态传入场景路径
		SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)
	)

	# 取消 -> 恢复玩家移动
	dialog.canceled.connect(func():
		_restore_player_movement(body, dialog)
	)

	# 点击关闭按钮 -> 等同于取消
	dialog.close_requested.connect(func():
		_restore_player_movement(body, dialog)
	)

## 功能：传送门的身体进入检测回调，用于切换到冒险关卡
## 参数：body (Node2D) - 进入传送门的实体（通常为玩家）
func _on_portal_to_boss_body_entered(body: Node2D) -> void:
		if body is Player:
			# 通过 SceneLoader 执行淡入淡出场景切换
			# TODO: 后续可根据实际关卡 ID 动态传入场景路径
			SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)

# ==============================================================================
#   lobby_world.gd
#   功能：游戏大厅场景总控制器。管理玩家出生与游戏状态，并在就绪时协调
#        子场景传送系统的初始化（触发 SubSceneManager 发现与注册流程）。
#   场景树预期包含的子节点：
#     - SubSceneManager      子场景生命周期管理
#     - LobbyPortalManager   传送网络与过渡控制（依赖 SubSceneManager）
#     - PiPViewportController  画中画视口
# ==============================================================================
extends Node2D
class_name LobbyWorld

# ========================== 节点引用模块 ==========================
## 玩家出生点标记（需在场景中设置 %PlayerSpawn 唯一命名）
@onready var player_spawn: Marker2D = %PlayerSpawn

## 全局玩家对象引用
@onready var player: Player = Global.player

## 子场景管理器（用于启动时触发场景发现）
@onready var sub_scene_manager: SubSceneManager = $SubSceneManager

## 传送管理器（用于连接信号等后续扩展）
@onready var portal_manager: LobbyPortalManager = $LobbyPortalManager as LobbyPortalManager

# ========================== 变量定义模块 ==========================
## 传送门对话框是否已打开（防止 body_entered 重复触发）
## 注意：旧版系统使用 ConfirmationDialog，新版改用 PortalZone 组件
## 此变量仅用于旧版 portal 信号处理（进入 dungeon/boss 等跨世界传送）
var _is_portal_dialog_open: bool = false

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化大厅场景
func _ready() -> void:
	# 1) 将玩家放置到出生点
	if player and player_spawn:
		player.global_position = player_spawn.global_position

	# 2) 设置游戏状态为大厅
	GameManager.set_game_state(GameManager.GameState.LOBBY)

	# 3) 触发子场景发现与注册（PortalZone 自动注册到 LobbyPortalManager）
	if sub_scene_manager:
		sub_scene_manager.discover_and_register()

	print("LobbyWorld: 大厅初始化完成（含子场景传送系统）")

# ========================== 旧版传送门处理模块 ==========================
## 注意：以下两个方法处理从大厅主场景进入游戏世界副本的旧版传送门，
##       与新版子场景间 PiP 传送系统无关，保留以兼容场景中已放置的 PortalToDungeon/PortalToBoss 节点。
##       将来如需统一，可将这些入口也改为 PortalZone 组件。

## 功能：恢复玩家移动并清理对话框
## 参数：player_obj (Player) - 玩家对象；dialog (ConfirmationDialog) - 对话框实例
func _restore_player_movement(player_obj: Player, dialog: ConfirmationDialog) -> void:
	_is_portal_dialog_open = false

	if is_instance_valid(player_obj):
		player_obj.enable_movement()

	if is_instance_valid(dialog):
		dialog.queue_free()

## 功能：传送门身体进入检测回调，进入冒险关卡
## 参数：body (Node2D) - 进入触发器的节点
func _on_portal_to_dungeon_body_entered(body: Node2D) -> void:
	if not (body is Player) or _is_portal_dialog_open:
		return

	_is_portal_dialog_open = true
	body.disable_movement()

	var dialog := ConfirmationDialog.new()
	dialog.title = "进入挑战"
	dialog.dialog_text = "确定要进入挑战吗？"
	dialog.ok_button_text = "确认"
	dialog.cancel_button_text = "取消"
	dialog.exclusive = true
	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)
	)

	dialog.canceled.connect(func():
		_restore_player_movement(body, dialog)
	)

	dialog.close_requested.connect(func():
		_restore_player_movement(body, dialog)
	)

## 功能：传送门身体进入检测回调，进入首领关卡
## 参数：body (Node2D) - 进入触发器的节点
func _on_portal_to_boss_body_entered(body: Node2D) -> void:
	if body is Player:
		SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)

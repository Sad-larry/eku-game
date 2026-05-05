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

# ========================== 生命周期模块 ==========================
## 功能：大厅场景就绪时，将玩家放置到出生点并设置游戏状态为大厅
func _ready() -> void:
	# 将玩家位置设置为出生点坐标
	if player and player_spawn:
		player.global_position = player_spawn.global_position
	
	# 设置游戏状态为大厅（确保 HUD 等系统正确响应）
	GameManager.set_game_state(GameManager.GameState.LOBBY)
	print("LobbyWorld: 大厅初始化完成")

# ========================== 信号回调模块 ==========================
## 功能：传送门的身体进入检测回调，用于切换到冒险关卡
## 参数：body (Node2D) - 进入传送门的实体（通常为玩家）
func _on_portal_to_dungeon_body_entered(body: Node2D) -> void:
	if body is Player:
		# 通过 SceneLoader 执行淡入淡出场景切换
		# TODO: 后续可根据实际关卡 ID 动态传入场景路径
		SceneLoader.change_scene(Global.ROOM_01_SCENE_PATH)

## 功能：传送门的身体进入检测回调，用于切换到冒险关卡
## 参数：body (Node2D) - 进入传送门的实体（通常为玩家）
func _on_portal_to_boss_body_entered(body: Node2D) -> void:
		if body is Player:
			# 通过 SceneLoader 执行淡入淡出场景切换
			# TODO: 后续可根据实际关卡 ID 动态传入场景路径
			SceneLoader.change_scene(Global.ROOM_02_SCENE_PATH)

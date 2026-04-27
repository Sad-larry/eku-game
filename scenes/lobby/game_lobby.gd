extends Node2D
class_name GameLobby
# TODO GameLobby中的RoomBase后续需要替换掉，因为这个是冒险地图专用的房间基类
# 因此，GameLobby不需要被RoomManager所管理

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	player.global_position = Vector2(150, 150)

func _on_area_2d_body_entered(_body: Node2D) -> void:
	call_deferred("change_scene_safe", Global.ROOM_01_SCENE_PATH)

func change_scene_safe(scene):
	SceneLoader.change_scene(scene)

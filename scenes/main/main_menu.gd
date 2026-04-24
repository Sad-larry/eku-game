extends Node2D
class_name MainMenu

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	player.global_position = Vector2(50, 50)

func _on_area_2d_body_entered(_body: Node2D) -> void:
	var room_01_scene = load(Global.ROOM_01_SCENE_PATH)
	call_deferred("change_scene_safe", room_01_scene)

func change_scene_safe(scene):
	get_tree().change_scene_to_packed(scene)

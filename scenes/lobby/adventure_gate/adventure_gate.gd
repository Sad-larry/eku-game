extends Node2D
class_name AdventureGate

## 功能：传送门身体进入检测回调，进入首领关卡
func _on_portal_to_adventure_body_entered(body: Node2D) -> void:
	if body is Player:
		SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)

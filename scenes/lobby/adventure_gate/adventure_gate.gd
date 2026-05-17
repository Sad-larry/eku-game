# ==============================================================================
#   adventure_gate.gd
#   功能：冒险大门（传送门），玩家进入后切换到游戏世界场景。
# ==============================================================================
extends Node2D
class_name AdventureGate

# ========================== 信号回调模块 ==========================
## 功能：传送门身体进入检测回调，进入首领关卡
func _on_portal_to_adventure_body_entered(body: Node2D) -> void:
	if body is Player:
		SceneLoader.change_scene(Global.GAME_WORLD_SCENE_PATH)

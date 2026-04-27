extends Control
class_name GameOver

@onready var back_button: Button = %BackButton


func _on_back_button_pressed() -> void:
	UIManager.close_game_over()
	await SceneLoader.change_scene(Global.GAME_LOBBY_SCENE_PATH)
	GameManager.set_game_state(GameManager.GameState.IN_GAME)

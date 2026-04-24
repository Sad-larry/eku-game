extends Control
class_name GameOver

@onready var back_button: Button = %BackButton


func _on_back_button_pressed() -> void:
	UIManager.close_game_over()

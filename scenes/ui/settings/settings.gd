extends Control
class_name Settings

@onready var button: Button = %BackButton

func _on_button_pressed() -> void:
	UIManager.close_settings_menu()

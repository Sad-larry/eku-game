# ==============================================================================
#   event_npc.gd
#   功能：事件 NPC 控制器。按 F 交互触发对话系统。
# ==============================================================================
extends StaticBody2D
class_name EventNPC

@export var dialog_data: DialogData

@onready var interactable: InteractableArea = $InteractableArea
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	interactable.prompt_text = "按 F 对话"
	interactable.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if dialog_data == null:
		UIManager.show_message("这个 NPC 没什么要说的...")
		RoomManager.set_state(_get_coord(), RoomManager.RoomState.CLEARED)
		return

	var dialog_ui := UIManager.open_ui("dialog_box")
	if dialog_ui and dialog_ui.has_method("setup"):
		dialog_ui.setup(dialog_data)
		dialog_ui.dialog_ended.connect(_on_dialog_ended)

func _on_dialog_ended() -> void:
	var coord := _get_coord()
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

func _get_coord() -> Vector2i:
	var chunk_manager := get_tree().get_first_node_in_group("chunk_manager")
	if chunk_manager and chunk_manager.has_method("_pixel_to_chunk"):
		return chunk_manager._pixel_to_chunk(global_position)
	return Vector2i.ZERO

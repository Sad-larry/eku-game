# ==============================================================================
#   interactable_area.gd
#   功能：通用交互区域组件。当玩家进入检测区域时显示交互提示，
#        按下交互键（F）后触发指定行为（如打开 UI 面板）。
#   用法：作为子节点挂在可交互物体下，设置 target_ui_name 和提示文本即可。
# ==============================================================================
extends Area2D
class_name InteractableArea

## 交互提示文本（显示在 Label 中）
@export var prompt_text: String = "按 F 交互"

## 检测半径（圆形碰撞体大小）
@export var radius: float = 40.0

## 按下交互键后打开的 UI 名称（传给 UIManager.open_ui），若为空则只发射 interacted 信号
@export var target_ui_name: String = ""

## 玩家进入/离开交互区域时触发
signal player_entered()
signal player_exited()

## 玩家在此区域按下交互键时触发
signal interacted()

@onready var _prompt_label: Label = %PromptLabel
@onready var _collision_shape: CollisionShape2D = %CollisionShape

var _player_inside: bool = false
var _is_active: bool = false

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = radius
	_collision_shape.shape = shape

	_prompt_label.text = prompt_text
	_prompt_label.visible = false
	_prompt_label.z_index = 99

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or _is_active:
		return
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		_activate()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player_inside = true
		_prompt_label.visible = true
		player_entered.emit()

func _on_body_exited(body: Node) -> void:
	if body is Player:
		_player_inside = false
		if _is_active and not target_ui_name.is_empty():
			UIManager.close_ui(target_ui_name)
		else:
			_prompt_label.visible = false
		player_exited.emit()

func _activate() -> void:
	if _is_active:
		return
	_is_active = true
	_prompt_label.visible = false
	interacted.emit()

	if not target_ui_name.is_empty():
		var instance: Node = UIManager.open_ui(target_ui_name)
		if instance:
			instance.tree_exited.connect(_on_ui_closed)
		else:
			_is_active = false
	else:
		_is_active = false

func _on_ui_closed() -> void:
	_is_active = false
	if _player_inside:
		_prompt_label.visible = true

# ==============================================================================
#   dialog_box.gd
#   功能：对话框 UI。支持打字机效果、选项按钮。
# ==============================================================================
extends CanvasLayer
class_name DialogBox

signal dialog_ended

var _dialog_data: DialogData
var _current_line_index: int = 0
var _is_typing: bool = false
var _full_text: String = ""

@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/TextLabel
@onready var choices_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var continue_label: Label = $Panel/MarginContainer/VBoxContainer/ContinueLabel

func _ready() -> void:
	choices_container.visible = false
	continue_label.visible = false

func setup(data: DialogData) -> void:
	_dialog_data = data
	_current_line_index = 0
	_show_current_line()

func _show_current_line() -> void:
	if _current_line_index >= _dialog_data.lines.size():
		_show_choices()
		return

	var line: DialogLine = _dialog_data.lines[_current_line_index]
	speaker_label.text = line.speaker_name
	_full_text = line.text
	text_label.text = ""
	continue_label.visible = false
	_start_typewriter()

func _start_typewriter() -> void:
	_is_typing = true
	text_label.text = ""
	for i in _full_text.length():
		text_label.text += _full_text[i]
		await get_tree().create_timer(0.03).timeout
		if not _is_typing:
			break
	text_label.text = _full_text
	_is_typing = false
	continue_label.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F or event.keycode == KEY_SPACE:
			if _is_typing:
				# 跳过打字机效果
				_is_typing = false
				text_label.text = _full_text
				continue_label.visible = true
			elif continue_label.visible:
				_current_line_index += 1
				_show_current_line()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()

func _show_choices() -> void:
	speaker_label.text = ""
	text_label.text = ""
	continue_label.visible = false

	if _dialog_data.choices.is_empty():
		_close()
		return

	choices_container.visible = true
	for child in choices_container.get_children():
		child.queue_free()

	for i in _dialog_data.choices.size():
		var choice: DialogChoice = _dialog_data.choices[i]
		var button := Button.new()
		button.text = choice.text
		if choice.cost > 0:
			button.text += " (%d 金币)" % choice.cost
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)

func _on_choice_selected(index: int) -> void:
	var choice: DialogChoice = _dialog_data.choices[index]
	EventBus.dialog_choice_made.emit(index)

	match choice.choice_type:
		DialogChoice.ChoiceType.TRADE:
			if choice.cost > 0:
				var current_coin := CurrencyManager.get_current_coin()
				if current_coin < choice.cost:
					UIManager.show_message("金币不足！")
					return
				CurrencyManager.spend_run_coin(choice.cost)
			if choice.reward_coin > 0:
				CurrencyManager.add_coin(choice.reward_coin)
				UIManager.show_message("获得 %d 金币" % choice.reward_coin)
			if choice.reward_heal_pct > 0 and Global.player:
				var heal := int(Global.player.health_component.max_health * choice.reward_heal_pct)
				Global.player.health_component.heal(heal)
				UIManager.show_message("回复 %d 生命值" % heal)
		DialogChoice.ChoiceType.GIFT:
			if choice.reward_coin > 0:
				CurrencyManager.add_coin(choice.reward_coin)
				UIManager.show_message("获得 %d 金币" % choice.reward_coin)
		DialogChoice.ChoiceType.INFO:
			pass
		DialogChoice.ChoiceType.QUEST:
			pass
		DialogChoice.ChoiceType.LEAVE:
			pass

	_close()

func _close() -> void:
	EventBus.dialog_ended.emit()
	dialog_ended.emit()
	queue_free()

func get_blocked_input_prefixes() -> Array[String]:
	return ["skill_", "attack"]

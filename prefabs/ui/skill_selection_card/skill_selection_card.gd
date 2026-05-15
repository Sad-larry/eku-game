# ==============================================================================
#   skill_selection_card.gd
#   功能：技能选择面板中的技能卡牌按钮，显示技能图标、名称、类型角标、
#        选中高亮和已装备标记。
# ==============================================================================
extends Button
class_name SkillSelectionCard

signal selected(skill_id: String)

var skill_data: SkillEffect
var _skill_id: String = ""

@onready var _icon: TextureRect = %CardIcon
@onready var _name_label: Label = %CardName
@onready var _type_tag: Label = %CardTypeTag
@onready var _highlight: Panel = %HighlightBorder
@onready var _equipped_mark: Label = %EquippedMark

func setup(data: SkillEffect, equipped_ids: Array = []) -> void:
	skill_data = data
	_skill_id = data.id
	_icon.texture = data.icon
	_name_label.text = data.name

	var type_name = SkillEffect.SkillType.keys()[data.type]
	_type_tag.text = type_name

	match data.type:
		SkillEffect.SkillType.INITIATOR:
			_type_tag.self_modulate = Color(0.2, 0.8, 0.2)
		SkillEffect.SkillType.FINISHER:
			_type_tag.self_modulate = Color(0.8, 0.2, 0.2)
		SkillEffect.SkillType.CONTROL:
			_type_tag.self_modulate = Color(0.2, 0.4, 0.8)
		SkillEffect.SkillType.SURVIVAL:
			_type_tag.self_modulate = Color(0.8, 0.6, 0.2)
		_:
			_type_tag.self_modulate = Color(0.5, 0.5, 0.5)

	_equipped_mark.visible = _skill_id in equipped_ids
	set_highlight(false)

func set_highlight(enabled: bool) -> void:
	_highlight.visible = enabled

func _pressed() -> void:
	selected.emit(_skill_id)

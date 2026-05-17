# ==============================================================================
#   skill_selection_card.gd
#   功能：技能选择面板中的技能卡牌按钮，显示技能图标、名称、类型角标、
#        选中高亮和已装备标记。
# ==============================================================================
extends Button
class_name SkillSelectionCard

# ========================== 信号声明模块 ==========================
## 触发时机：卡牌被选中时
## 参数：skill_id (String) - 选中的技能 ID
signal selected(skill_id: String)

# ========================== 变量定义模块 ==========================
## 技能数据引用
var skill_data: SkillEffect
## 技能唯一标识符
var _skill_id: String = ""

# ========================== 节点引用模块 ==========================
@onready var _icon: TextureRect = %CardIcon
@onready var _name_label: Label = %CardName
@onready var _type_tag: Label = %CardTypeTag
@onready var _highlight: Panel = %HighlightBorder
@onready var _equipped_mark: Label = %EquippedMark

# ========================== 公共 API 模块 ==========================
## 功能：初始化技能卡牌显示
## 参数：data (SkillEffect) - 技能数据；equipped_ids (Array) - 已装备技能 ID 列表
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

## 功能：设置卡牌高亮状态
## 参数：enabled (bool) - 是否高亮
func set_highlight(enabled: bool) -> void:
	_highlight.visible = enabled

# ========================== 信号回调模块 ==========================
## 功能：按钮被按下时的回调，发射 selected 信号
func _pressed() -> void:
	selected.emit(_skill_id)

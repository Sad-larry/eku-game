# ==============================================================================
#   shop_skill_list_item.gd
#   功能：商店技能列表项按钮，显示技能图标、名称、类型标签、解锁状态锁标。
# ==============================================================================
extends Button
class_name ShopSkillListItem

# ========================== 信号声明模块 ==========================
## 触发时机：列表项被选中时
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
@onready var _level_tag: Label = %LevelTag
@onready var _lock_mark: Label = %LockMark
@onready var _highlight: Panel = %HighlightBorder

# ========================== 公共 API 模块 ==========================
## 功能：初始化列表项显示
## 参数：data (SkillEffect) - 技能数据
func setup(data: SkillEffect) -> void:
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

	refresh_state()
	refresh_level()
	set_highlight(false)

## 功能：根据 SkillUpgradeManager 刷新等级标签
func refresh_level() -> void:
	var level: int = SkillUpgradeManager.get_skill_level(_skill_id)
	var max_level: int = SkillUpgradeManager.get_max_level(_skill_id)
	_level_tag.text = "Lv.%d/%d" % [level, max_level]

## 功能：根据 SkillUnlockManager 刷新解锁状态显示
func refresh_state() -> void:
	var unlocked: bool = SkillUnlockManager.is_skill_unlocked(_skill_id)
	_lock_mark.visible = not unlocked
	_icon.self_modulate = Color(1, 1, 1, 1.0) if unlocked else Color(0.4, 0.4, 0.4, 1.0)

## 功能：设置列表项高亮状态
## 参数：enabled (bool) - 是否高亮
func set_highlight(enabled: bool) -> void:
	_highlight.visible = enabled

# ========================== 信号回调模块 ==========================
## 功能：按钮被按下时的回调，发射 selected 信号
func _pressed() -> void:
	selected.emit(_skill_id)

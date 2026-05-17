# ==============================================================================
#   skill_slot.gd
#   功能：技能快捷栏槽位控件，显示技能图标、冷却遮罩和冷却时间文本。
#        支持鼠标点击触发技能、键盘触发的按下闪烁反馈、运行时冷却进度显示。
#   冷却显示：通过调节遮罩 ColorRect 的高度来呈现冷却进度（自上而下填充）。
# ==============================================================================
extends MarginContainer
class_name SkillSlot

# ========================== 信号声明模块 ==========================
signal slot_clicked(slot_index: int)

# ========================== 导出变量模块 ==========================
@export var skill_index: int = 0

# ========================== 节点引用模块 ==========================
@onready var _button: TextureButton = %Button
@onready var _icon: TextureRect = %SkillIcon
@onready var _overlay: ColorRect = %CooldownOverlay
@onready var _cd_label: Label = %CooldownLabel

# ========================== 变量定义模块 ==========================
var _parent_height: float = 0.0

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)
	await get_tree().process_frame
	_parent_height = _overlay.get_parent().size.y

func _process(_delta: float) -> void:
	# 确保父节点尺寸变化后仍能同步
	if _parent_height <= 0.0:
		_parent_height = _overlay.get_parent().size.y

# ========================== 公共 API 模块 ==========================
func set_skill_data(data: SkillEffect) -> void:
	if data:
		_icon.texture = data.icon
		_button.disabled = false
		tooltip_text = data.name
	else:
		_icon.texture = null
		_button.disabled = true
		tooltip_text = ""

func flash_pressed() -> void:
	_button.button_pressed = true
	await get_tree().create_timer(0.08).timeout
	if is_inside_tree():
		_button.button_pressed = false

func update_cooldown(remaining: float, total: float) -> void:
	if total <= 0.0:
		_overlay.visible = false
		_cd_label.visible = false
		return

	var ratio: float = remaining / total
	_overlay.visible = ratio > 0.0

	if _overlay.visible and _parent_height > 0.0:
		_overlay.size.y = _parent_height * ratio
		_overlay.position.y = _parent_height - _overlay.size.y

	if remaining > 0.0:
		_cd_label.visible = true
		_cd_label.text = "%.1f" % remaining
	else:
		_cd_label.visible = false

func hide_cooldown() -> void:
	_overlay.visible = false
	_cd_label.visible = false
	if _parent_height > 0.0:
		_overlay.size.y = 0.0

func _on_button_pressed() -> void:
	slot_clicked.emit(skill_index)

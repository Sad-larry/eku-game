# ==============================================================================
#   SkillSlot.gd
#   功能：技能快捷栏槽位控件，显示技能图标、冷却遮罩和冷却时间文本。
#        支持鼠标点击触发技能、键盘触发的按下闪烁反馈、运行时冷却进度显示。
# ==============================================================================
extends MarginContainer
class_name SkillSlot

# ========================== 信号声明模块 ==========================
## 触发时机：技能槽被鼠标点击时
signal slot_clicked(slot_index: int)

# ========================== 导出变量模块 ==========================
## 技能槽位索引（用于标识第几个技能槽）
@export var skill_index: int = 0

# ========================== 节点引用模块 ==========================
## 技能槽位按钮（用于触发技能）
@onready var _button: TextureButton = %Button

## 技能图标显示区域
@onready var _icon: TextureRect = %SkillIcon

## 冷却遮罩层（显示冷却进度的半透明覆盖层）
@onready var _overlay: ColorRect = %CooldownOverlay

## 冷却倒计时文本标签
@onready var _cd_label: Label = %CooldownLabel

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时连接按钮点击信号
func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)

# ========================== 公共 API 模块 ==========================
## 功能：设置技能槽的技能数据
## 参数：data (SkillEffect) - 技能资源，若为 null 则清空槽位
func set_skill_data(data: SkillEffect) -> void:
	if data:
		_icon.texture = data.icon
		_button.disabled = false
		tooltip_text = data.name
	else:
		_icon.texture = null
		_button.disabled = true
		tooltip_text = ""

## 功能：播放按键按下反馈（键盘触发时调用，短暂闪烁槽位）
func flash_pressed() -> void:
	_button.button_pressed = true
	await get_tree().create_timer(0.08).timeout
	if is_inside_tree():
		_button.button_pressed = false

## 功能：更新冷却显示（进度遮罩和倒计时文本）
## 参数：remaining (float) - 当前剩余冷却时间（秒）；total (float) - 技能总冷却时间（秒）
func update_cooldown(remaining: float, total: float) -> void:
	if total <= 0.0:
		_overlay.visible = false
		_cd_label.visible = false
		return
	var ratio: float = remaining / total
	_overlay.visible = ratio > 0.0
	# 通过着色器参数控制冷却进度
	if _overlay.material:
		_overlay.material.set_shader_parameter("fill_ratio", ratio)

	# 备用方案：手动调整遮罩高度
	_overlay.size.y = _overlay.get_parent().size.y * ratio

	if remaining > 0.0:
		_cd_label.visible = true
		_cd_label.text = "%.1f" % remaining
	else:
		_cd_label.visible = false

## 功能：隐藏冷却显示（冷却结束时调用）
func hide_cooldown() -> void:
	_overlay.visible = false
	_cd_label.visible = false

# ========================== 信号回调模块 ==========================
## 功能：按钮被点击时发射 clicked 信号
func _on_button_pressed() -> void:
	slot_clicked.emit(skill_index)

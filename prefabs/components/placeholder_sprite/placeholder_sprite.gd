# ==============================================================================
#   placeholder_sprite.gd
#   功能：占位图组件，挂载到任意节点上显示彩色方框和标签。
#         用于开发阶段替代实际美术资源，快速搭建可玩原型。
# ==============================================================================
extends Node2D
class_name PlaceholderSprite

# ========================== 信号声明模块 ==========================
## 占位图更新时触发
signal placeholder_updated()

# ========================== 导出变量模块 ==========================
## 占位图类型 ("player", "enemy", "elite", "boss", "npc", "item", "trap", "portal", "custom")
@export var placeholder_type: String = "custom":
	set(value):
		placeholder_type = value
		_update_placeholder()

## 自定义颜色（当 placeholder_type 为 "custom" 时使用）
@export var custom_color: Color = Color(0.5, 0.5, 0.5, 0.8):
	set(value):
		custom_color = value
		_update_placeholder()

## 占位图尺寸
@export var placeholder_size: Vector2 = Vector2(32, 32):
	set(value):
		placeholder_size = value
		_update_placeholder()

## 自定义标签文字（留空则使用类型默认标签）
@export var custom_label: String = "":
	set(value):
		custom_label = value
		_update_placeholder()

## 标签文字颜色
@export var label_color: Color = Color.WHITE:
	set(value):
		label_color = value
		_update_placeholder()

## 标签字体大小
@export var font_size: int = 10:
	set(value):
		font_size = value
		_update_placeholder()

## 是否显示边框
@export var show_border: bool = true:
	set(value):
		show_border = value
		_update_placeholder()

## 边框颜色
@export var border_color: Color = Color(1, 1, 1, 0.3):
	set(value):
		border_color = value
		_update_placeholder()

## 边框厚度
@export var border_thickness: float = 2.0:
	set(value):
		border_thickness = value
		_update_placeholder()

# ========================== 节点引用模块 ==========================
@onready var background: ColorRect = $Background
@onready var border: ColorRect = $Border
@onready var label: Label = $Label

# ========================== 变量定义模块 ==========================
## 当前使用的颜色
var _current_color: Color

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_update_placeholder()

# ========================== 更新方法 ==========================
## 功能：更新占位图显示
func _update_placeholder() -> void:
	# 如果节点还未就绪，等待就绪后再更新
	if not is_inside_tree():
		return

	# 获取颜色
	_current_color = _get_color_for_type(placeholder_type)

	# 更新背景
	if background:
		background.custom_minimum_size = placeholder_size
		background.size = placeholder_size
		background.position = -placeholder_size / 2.0
		background.color = _current_color

	# 更新边框
	if border:
		if show_border:
			border.visible = true
			border.custom_minimum_size = placeholder_size + Vector2(border_thickness, border_thickness) * 2
			border.size = placeholder_size + Vector2(border_thickness, border_thickness) * 2
			border.position = -placeholder_size / 2.0 - Vector2(border_thickness, border_thickness)
			border.color = border_color
		else:
			border.visible = false

	# 更新标签
	if label:
		var display_label := custom_label
		if display_label.is_empty():
			display_label = _get_default_label(placeholder_type)

		label.text = display_label
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = placeholder_size
		label.position = -placeholder_size / 2.0
		label.add_theme_color_override("font_color", label_color)
		label.add_theme_font_size_override("font_size", font_size)

	# 发送更新信号
	placeholder_updated.emit()

# ========================== 工具方法 ==========================
## 功能：根据类型获取颜色
func _get_color_for_type(type: String) -> Color:
	match type:
		"player":
			return PlaceholderFactory.PLAYER_COLOR
		"enemy":
			return PlaceholderFactory.ENEMY_COLOR
		"elite":
			return PlaceholderFactory.ELITE_COLOR
		"boss":
			return PlaceholderFactory.BOSS_COLOR
		"npc":
			return PlaceholderFactory.NPC_COLOR
		"item":
			return PlaceholderFactory.ITEM_COLOR
		"trap":
			return PlaceholderFactory.TRAP_COLOR
		"portal":
			return PlaceholderFactory.PORTAL_COLOR
		"custom":
			return custom_color
		_:
			return Color(0.5, 0.5, 0.5, 0.8)

## 功能：根据类型获取默认标签
func _get_default_label(type: String) -> String:
	match type:
		"player":
			return "玩家"
		"enemy":
			return "敌人"
		"elite":
			return "精英"
		"boss":
			return "Boss"
		"npc":
			return "NPC"
		"item":
			return "物品"
		"trap":
			return "陷阱"
		"portal":
			return "传送门"
		_:
			return type

# ========================== 公共 API ==========================
## 功能：设置占位图类型并更新显示
## 参数：type (String) - 占位图类型
func set_type(type: String) -> void:
	placeholder_type = type

## 功能：设置自定义颜色
## 参数：color (Color) - 自定义颜色
func set_color(color: Color) -> void:
	placeholder_type = "custom"
	custom_color = color

## 功能：设置自定义标签
## 参数：text (String) - 标签文字
func set_label(text: String) -> void:
	custom_label = text
	_update_placeholder()

## 功能：设置占位图尺寸
## 参数：size (Vector2) - 新尺寸
func set_size(size: Vector2) -> void:
	placeholder_size = size

## 功能：获取当前颜色
## 返回值：Color - 当前使用的颜色
func get_current_color() -> Color:
	return _current_color

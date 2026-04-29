# ==============================================================================
#   SkillSlot.gd
#   功能：技能快捷栏槽位控件，显示技能图标、冷却遮罩和冷却时间文本。
#        支持运行时更新技能数据以及实时显示剩余冷却进度。
# ==============================================================================
extends MarginContainer
class_name SkillSlot

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

# ========================== 公共 API 模块 ==========================
## 功能：设置技能槽的技能数据
## 参数：data (SkillEffect) - 技能资源，若为 null 则清空槽位
func set_skill_data(data: SkillEffect) -> void:
	if data:
		_icon.texture = data.icon
		_button.disabled = false
	else:
		_icon.texture = null
		_button.disabled = true

## 功能：更新冷却显示（进度遮罩和倒计时文本）
## 参数：remaining (float) - 当前剩余冷却时间（秒）；total (float) - 技能总冷却时间（秒）
func update_cooldown(remaining: float, total: float) -> void:
	# 总冷却时间为 0 或负数时，代表无冷却，隐藏冷却相关 UI
	if total <= 0.0:
		_overlay.visible = false
		_cd_label.visible = false
		return

	# 计算冷却进度比例（剩余 / 总时长）
	var ratio: float = remaining / total
	
	# 显示冷却遮罩（剩余时间 > 0 时才显示）
	_overlay.visible = ratio > 0.0
	
	# 通过着色器参数控制冷却进度（方案一：使用 Shader 绘制扇形/径向填充）
	_overlay.material.set_shader_parameter("fill_ratio", ratio)
	
	# 方案二：手动调整遮罩的缩放或位置（备用降级方案）
	# 根据父容器的尺寸动态设置遮罩高度，实现自上而下的填充效果
	_overlay.size.y = _overlay.get_parent().size.y * ratio

	# 显示冷却倒计时文本（剩余时间 > 0 时显示）
	if remaining > 0.0:
		_cd_label.visible = true
		_cd_label.text = "%.1f" % remaining  # 保留一位小数
	else:
		_cd_label.visible = false

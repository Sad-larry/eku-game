# ==============================================================================
#   damage_number.gd
#   功能：伤害数字显示控件，用于战斗场景中动态生成并弹出伤害数值、暴击特效、
#        治疗数值等视觉反馈，动画结束后自动销毁。
# ==============================================================================
extends Control
class_name DamageNumber

# ========================== 节点引用模块 ==========================
## 显示数值的标签节点（需在场景树中存在名为 ValueLabel 的 Label 子节点）
@onready var _label: Label = $ValueLabel
## 动画播放器节点（需在场景树中存在名为 AnimationPlayer 的子节点）
@onready var _anim: AnimationPlayer = $AnimationPlayer

# ========================== 常量定义模块 ==========================
## 不同伤害类型的显示颜色配置
const COLORS: Dictionary = {
	"normal": Color.WHITE,                      ## 普通伤害：白色
	"crit":   Color(1.0, 0.85, 0.0),         ## 暴击伤害：金色
	"heal":   Color.GREEN,                      ## 治疗数值：绿色
}

# ========================== 公共 API 模块 ==========================
## 功能：初始化伤害数字控件，设置显示数值和颜色样式
## 参数：value (float) - 要显示的数值；is_crit (bool) - 是否为暴击伤害（默认 false）
func setup(value: float, is_crit: bool = false) -> void:
	_label.text = str(int(value))
	_label.self_modulate = COLORS["crit"] if is_crit else COLORS["normal"]
	_start_popup()

## 功能：初始化自定义文本控件（用于飘字提示，如 "+1 尘元"）
## 参数：text (String) - 要显示的文本；color (Color) - 文本颜色
func setup_text(text: String, color: Color = Color.WHITE) -> void:
	_label.text = text
	_label.self_modulate = color
	_start_popup()

## 功能：启动弹出动画并连接销毁回调
func _start_popup() -> void:
	_anim.play("popup")
	_anim.animation_finished.connect(_on_anim_finished)

# ========================== 内部回调模块 ==========================
## 功能：动画播放完成时的回调
## 参数：_name (String) - 动画名称（未使用）
## 说明：动画结束后自动销毁自身节点，释放内存
func _on_anim_finished(_name: String) -> void:
	queue_free()

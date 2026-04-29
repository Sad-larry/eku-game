# ==============================================================================
#   HealthBar.gd
#   功能：血条 UI 控件，支持主血条（即时填充）和延迟伤害条（缓慢跟随）的双层显示效果，
#        同时显示血量数字。颜色可通过导出变量自定义。
# ==============================================================================
extends Control
class_name HealthBar

# ========================== 导出变量模块 ==========================
## 血条背景颜色（延迟条的背景色）
@export var back_color: Color

## 主血条填充颜色（即时响应部分）
@export var fill_color: Color

## 延迟条填充颜色（受伤后的缓慢回落效果）
@export var delay_color: Color

# ========================== 节点引用模块 ==========================
## 主血条进度条节点（即时血量变化）
@onready var progress_bar: ProgressBar = $ProgressBar

## 血量数字显示标签
@onready var health_label: Label = $HealthAmount

## 延迟伤害条进度条节点（缓慢跟随，模拟受伤后血条渐变效果）
@onready var delay_bar: ProgressBar = $DelayBar

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化血条的样式（背景、主填充、延迟填充颜色）
func _ready() -> void:
	# 设置延迟条的背景样式（作为整体血条背景）
	var back_style := delay_bar.get_theme_stylebox("background").duplicate()
	back_style.bg_color = back_color
	delay_bar.add_theme_stylebox_override("background", back_style)
	
	# 设置主血条的填充样式（即时血量）
	var fill_style := progress_bar.get_theme_stylebox("fill").duplicate()
	fill_style.bg_color = fill_color
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# 设置延迟条的填充样式（缓慢跟随部分）
	var delay_style := delay_bar.get_theme_stylebox("fill").duplicate()
	delay_style.bg_color = delay_color
	delay_bar.add_theme_stylebox_override("fill", delay_style)

# ========================== 公共 API 模块 ==========================
## 功能：绑定血条到指定的生命值组件
## 参数：health_comp (HealthComponent) - 目标实体的生命值组件实例
## 说明：连接 health_updated 信号，并立即拉取初始血量值进行显示
func setup(health_comp: HealthComponent) -> void:
	health_comp.health_updated.connect(_on_health_bar_update)
	# 立即刷新初始血量（此时 health_comp 已完成 setup，值正确）
	_on_health_bar_update(health_comp.current_health, health_comp.max_health)

## 功能：更新血条显示（主血条值、血量数字、延迟条动画）
## 参数：current_health (int) - 当前生命值；max_health (int) - 最大生命值
func update_bar(current_health: int, max_health: int) -> void:
	health_label.text = str(current_health)
	progress_bar.max_value = max_health
	progress_bar.value = current_health
	
	# 延迟条缓慢跟随动画（0.8 秒缓动）
	var tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(delay_bar, "value", current_health, 0.8)

# ========================== 信号回调模块 ==========================
## 功能：生命值组件 health_updated 信号的回调
## 参数：current_health (int) - 当前生命值；max_health (int) - 最大生命值
func _on_health_bar_update(current_health: int, max_health: int) -> void:
	update_bar(current_health, max_health)

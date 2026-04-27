extends Control
class_name HealthBar

# 血条背景色 / 填充色
@export var back_color: Color
@export var fill_color: Color
@export var delay_color: Color # 受伤延迟条颜色
# 血条 + 血量数字文本
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var health_label: Label = $HealthAmount
@onready var delay_bar: ProgressBar = $DelayBar

# 新增：由外部实体调用，传入该实体自己的 HealthComponent
func setup(health_comp: HealthComponent) -> void:
	health_comp.health_updated.connect(_on_health_bar_update)
	# 立即拉取初始值（此时 health_comp 已经 setup 完毕，值正确）
	_on_health_bar_update(health_comp.current_health, health_comp.max_health)

# 初始化：动态设置血条颜色
func _ready() -> void:
	# 背景，只需要设置deleybar的背景就行，实际血条只需要填充色，实际血条在最顶端
	var back_style := delay_bar.get_theme_stylebox("background").duplicate()
	back_style.bg_color = back_color
	delay_bar.add_theme_stylebox_override("background", back_style)
	
	# 红色血条（立即
	var fill_style := progress_bar.get_theme_stylebox("fill").duplicate()
	fill_style.bg_color = fill_color
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# 淡红延迟条（缓慢
	var delay_style := delay_bar.get_theme_stylebox("fill").duplicate()
	delay_style.bg_color = delay_color
	delay_bar.add_theme_stylebox_override("fill", delay_style)
	
	
# 更新血条显示（血条 + 血量数字）
func update_bar(current_health: int, max_health: int) -> void:
	health_label.text = str(current_health)
	progress_bar.max_value = max_health
	progress_bar.value = current_health
	
	# 缓慢变
	var tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(delay_bar, "value", current_health, 0.8)
	
# 新增：私有回调，不再从 EventBus 接收
func _on_health_bar_update(current_health: int, max_health: int) -> void:
	update_bar(current_health, max_health)

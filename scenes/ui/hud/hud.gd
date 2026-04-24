extends CanvasLayer
class_name HUD

# 节点引用（通过编辑器绑定）
@onready var health_label: Label = %HealthLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var energy_label: Label = %EnergyLabel
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var combo_label: Label = %ComboLabel
@onready var skill_slots: Array[Button] = [
	%SkillSlot1,
	%SkillSlot2,
	%SkillSlot3,
	%SkillSlot4
]
@onready var pause_button: Button = %PauseButton

# 玩家属性默认值
var max_health: int = 100
var current_health: int = 100
var max_energy: int = 100
var current_energy: int = 50
var current_combo: int = 0

func _ready():
	# 初始化UI显示
	update_health_display()
	update_energy_display()
	update_combo_display()
	
	# 监听全局信号（关联Global单例）
	if Global:
		Global.connect("health_updated", _on_health_updated)
		Global.connect("energy_updated", _on_energy_updated)
		Global.connect("combo_updated", _on_combo_updated)
		
	
# 更新生命值显示（文本+进度条）
func update_health_display():
	health_label.text = "HP: %s/%s" % [current_health, max_health]
	health_bar.max_value = max_health
	health_bar.value = current_health

# 更新能量值显示（文本+进度条）
func update_energy_display():
	energy_label.text = "MP: %s/%s" % [current_energy, max_energy]
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy

# 更新连击数显示
func update_combo_display():
	combo_label.text = "Combo: %s" % current_combo

# 设置技能槽图标
func set_skill_slot_icon(slot_index: int, icon_texture: Texture2D):
	if slot_index >= 0 and slot_index < skill_slots.size():
		skill_slots[slot_index].texture = icon_texture

# 暂停按钮点击回调
func _on_pause_button_pressed():
	UIManager.open_pause_menu()

# 全局生命值更新信号回调
func _on_health_updated(new_health: int, new_max_health: int):
	current_health = new_health
	max_health = new_max_health
	update_health_display()

# 全局能量值更新信号回调
func _on_energy_updated(new_energy: int, new_max_energy: int):
	current_energy = new_energy
	max_energy = new_max_energy
	update_energy_display()

# 全局连击数更新信号回调
func _on_combo_updated(new_combo: int):
	current_combo = new_combo
	update_combo_display()

# 重置HUD状态（如玩家复活/新关卡）
func reset_hud():
	current_health = max_health
	current_energy = max_energy
	current_combo = 0
	update_health_display()
	update_energy_display()
	update_combo_display()
	# 清空技能槽
	for slot in skill_slots:
		slot.texture = null

func _on_skill_slot_1_pressed() -> void:
	UIManager.show_message("释放技能 1")

func _on_skill_slot_2_pressed() -> void:
	UIManager.show_message("释放技能 2")

func _on_skill_slot_3_pressed() -> void:
	UIManager.show_message("释放技能 3")

func _on_skill_slot_4_pressed() -> void:
	UIManager.show_message("释放技能 4")

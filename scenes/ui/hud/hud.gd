# ==============================================================================
#   HUD.gd
#   功能：游戏主界面 HUD（平视显示器），显示玩家生命值、能量值、连击数、金币数量、
#        技能快捷栏等信息，并监听全局事件总线（EventsBus）实时更新界面数据。
# ==============================================================================
extends CanvasLayer
class_name HUD

# ========================== 节点引用模块 ==========================
## 生命值数值文本标签
@onready var health_label: Label = %HealthLabel

## 生命值进度条
@onready var health_bar: ProgressBar = %HealthBar

## 能量值数值文本标签
@onready var energy_label: Label = %EnergyLabel

## 能量值进度条
@onready var energy_bar: ProgressBar = %EnergyBar

## 连击数文本标签
@onready var combo_label: Label = %ComboLabel

## 金币数量文本标签
@onready var coin_label: Label = %CoinLabel

## 技能快捷栏按钮数组（通过 %SkillSlot1 ~ %SkillSlot4 命名）
@onready var skill_slots: Array[Button] = [
	%SkillSlot1,
	%SkillSlot2,
	%SkillSlot3,
	%SkillSlot4
]

## 暂停按钮节点
@onready var pause_button: Button = %PauseButton

# ========================== 内部状态变量模块 ==========================
## 最大生命值
var max_health: int = 100

## 当前生命值
var current_health: int = 100

## 最大能量值
var max_energy: int = 100

## 当前能量值
var current_energy: int = 50

## 当前连击数
var current_combo: int = 0

## 当前金币持有数量
var coin_count: int = 0

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化 HUD 显示并连接全局信号
func _ready():
	# 初始化 UI 显示
	update_health_display()
	update_energy_display()
	update_combo_display()
	
	# 监听全局信号（通过 EventsBus 全局单例）
	EventBus.connect("health_updated", _on_health_updated)
	EventBus.connect("energy_updated", _on_energy_updated)
	EventBus.connect("combo_updated", _on_combo_updated)
	EventBus.connect("coin_collected", _on_coin_collected)

## 功能：节点退出场景树时断开全局信号连接（避免内存泄漏）
func _exit_tree() -> void:
	EventBus.disconnect("health_updated", _on_health_updated)
	EventBus.disconnect("energy_updated", _on_energy_updated)
	EventBus.disconnect("combo_updated", _on_combo_updated)
	EventBus.disconnect("coin_collected", _on_coin_collected)

# ========================== 界面更新方法模块 ==========================
## 功能：更新生命值显示（文本 + 进度条）
func update_health_display():
	health_label.text = "HP: %s/%s" % [current_health, max_health]
	health_bar.max_value = max_health
	health_bar.value = current_health

## 功能：更新能量值显示（文本 + 进度条）
func update_energy_display():
	energy_label.text = "MP: %s/%s" % [current_energy, max_energy]
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy

## 功能：更新连击数显示
func update_combo_display():
	combo_label.text = "Combo: %s" % current_combo

## 功能：设置指定技能槽位的图标
## 参数：slot_index (int) - 技能槽索引（0 ~ 3）；icon_texture (Texture2D) - 图标纹理
func set_skill_slot_icon(slot_index: int, icon_texture: Texture2D):
	if slot_index >= 0 and slot_index < skill_slots.size():
		skill_slots[slot_index].texture = icon_texture

## 功能：重置 HUD 状态（玩家复活或进入新关卡时调用）
func reset_hud():
	current_health = max_health
	current_energy = max_energy
	current_combo = 0
	update_health_display()
	update_energy_display()
	update_combo_display()
	# 清空所有技能槽图标
	for slot in skill_slots:
		slot.texture = null

# ========================== UI 按钮回调模块 ==========================
## 功能：暂停按钮点击时打开暂停菜单（委托给 UIManager）
func _on_pause_button_pressed():
	UIManager.open_pause_menu()

## 功能：技能槽 1 被按下时触发
func _on_skill_slot_1_pressed() -> void:
	UIManager.show_message("释放技能 1")

## 功能：技能槽 2 被按下时触发
func _on_skill_slot_2_pressed() -> void:
	UIManager.show_message("释放技能 2")

## 功能：技能槽 3 被按下时触发
func _on_skill_slot_3_pressed() -> void:
	UIManager.show_message("释放技能 3")

## 功能：技能槽 4 被按下时触发
func _on_skill_slot_4_pressed() -> void:
	UIManager.show_message("释放技能 4")

# ========================== 全局信号回调模块 ==========================
## 功能：生命值更新信号回调（来自 EventBus）
## 参数：new_health (int) - 新的当前生命值；new_max_health (int) - 新的最大生命值
func _on_health_updated(new_health: int, new_max_health: int):
	current_health = new_health
	max_health = new_max_health
	update_health_display()

## 功能：能量值更新信号回调（来自 EventBus）
## 参数：new_energy (int) - 新的当前能量值；new_max_energy (int) - 新的最大能量值
func _on_energy_updated(new_energy: int, new_max_energy: int):
	current_energy = new_energy
	max_energy = new_max_energy
	update_energy_display()

## 功能：连击数更新信号回调（来自 EventBus）
## 参数：new_combo (int) - 新的连击数
func _on_combo_updated(new_combo: int):
	current_combo = new_combo
	update_combo_display()

## 功能：金币收集信号回调（来自 EventBus）
## 参数：amount (int) - 本次收集的金币数量
func _on_coin_collected(amount: int) -> void:
	coin_count += amount
	coin_label.text = str(coin_count)

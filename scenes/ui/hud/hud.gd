# ==============================================================================
#   hud.gd
#   功能：游戏主界面 HUD，显示玩家生命值、能量值、连击数、金币数量、
#        技能快捷栏（图标、按下反馈、冷却遮罩）等信息。
#   设计原则：HUD 仅负责"接收并显示"，不做业务逻辑计算（如冷却倒计时
#            由 SkillRunner 在技能系统中负责，HUD 仅展示收到的数据）。
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

## 技能快捷栏槽位数组（通过 %SkillSlot1 ~ %SkillSlot4 命名）
@onready var skill_slots: Array[SkillSlot] = [
	%SkillSlot1,
	%SkillSlot2,
	%SkillSlot3,
	%SkillSlot4
]

## 暂停按钮节点
@onready var pause_button: Button = %PauseButton

# ========================== 常量定义模块 ==========================
## 输入动作名到技能槽索引的映射表
const SKILL_ACTION_TO_SLOT: Dictionary = {
	"skill_1": 0,
	"skill_2": 1,
	"skill_3": 2,
	"skill_4": 3,
}

# ========================== 内部状态变量模块 ==========================
var max_health: int = 100
var current_health: int = 100
var max_energy: int = 100
var current_energy: int = 50
var current_combo: int = 0
var coin_count: int = 0

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时进行初始化，包括状态显示、信号连接、技能槽初始化。
func _ready():
	# 初始化状态显示
	update_health_display()
	update_energy_display()
	update_combo_display()

	# 连接全局事件总线信号
	EventBus.health_updated.connect(_on_health_updated)
	EventBus.energy_updated.connect(_on_energy_updated)
	EventBus.combo_updated.connect(_on_combo_updated)
	EventBus.coin_collected.connect(_on_coin_collected)

	# 连接技能冷却信号（冷却计算由 SkillRunner 负责，HUD 仅展示）
	EventBus.skill_cooldown_updated.connect(_on_skill_cooldown_updated)
	EventBus.skill_cooldown_finished.connect(_on_skill_cooldown_finished)
	# 连接技能槽变更信号（当玩家更换技能时触发）
	EventBus.skill_slot_changed.connect(_on_skill_slot_changed)

	# 连接输入管理器的动作触发信号（键盘按下时闪烁技能槽）
	if InputManager.has_signal("action_triggered"):
		InputManager.action_triggered.connect(_on_input_action_triggered)

	# 连接技能槽点击信号（鼠标点击技能槽时转发给 EventBus）
	for i in range(skill_slots.size()):
		skill_slots[i].slot_clicked.connect(_on_skill_slot_clicked)

	# 绑定玩家就绪信号，延迟初始化技能槽图标
	if EventBus.player_ready.is_connected(_on_player_ready):
		EventBus.player_ready.disconnect(_on_player_ready)
	EventBus.player_ready.connect(_on_player_ready)

	# 若玩家已就绪，直接初始化
	if Global.player != null:
		_init_skill_slot_icons()

## 功能：节点退出场景树时断开所有全局信号连接，防止悬挂回调。
func _exit_tree() -> void:
	EventBus.health_updated.disconnect(_on_health_updated)
	EventBus.energy_updated.disconnect(_on_energy_updated)
	EventBus.combo_updated.disconnect(_on_combo_updated)
	EventBus.coin_collected.disconnect(_on_coin_collected)
	EventBus.skill_cooldown_updated.disconnect(_on_skill_cooldown_updated)
	EventBus.skill_cooldown_finished.disconnect(_on_skill_cooldown_finished)
	EventBus.skill_slot_changed.disconnect(_on_skill_slot_changed)

	if EventBus.player_ready.is_connected(_on_player_ready):
		EventBus.player_ready.disconnect(_on_player_ready)
	if InputManager.action_triggered.is_connected(_on_input_action_triggered):
		InputManager.action_triggered.disconnect(_on_input_action_triggered)

# ========================== 技能槽初始化模块 ==========================
## 功能：从 Global.player 获取技能数据，初始化 4 个技能槽的图标。
## 说明：技能数据存储在 PlayerSkillManager 中，通过 skill_manager.get_data_by_action()
##       根据输入动作名（如 "skill_1"）获取对应的 SkillEffect 资源。
func _init_skill_slot_icons() -> void:
	if not Global.player:
		return
	var player := Global.player as Player
	for i in range(skill_slots.size()):
		var action_name := "skill_%d" % [i + 1]
		var data := player.skill_manager.get_data_by_action(action_name)
		skill_slots[i].set_skill_data(data)
		skill_slots[i].hide_cooldown()

# ========================== 技能槽变更响应模块 ==========================
## 功能：当玩家更换技能时，更新对应技能槽的图标显示。
## 参数：slot_index (int) - 技能槽索引（0 ~ 3）
func _on_skill_slot_changed(slot_index: int) -> void:
	if not Global.player:
		return
	if slot_index < 0 or slot_index >= skill_slots.size():
		return
	var player := Global.player as Player
	var action_name := "skill_%d" % [slot_index + 1]
	var data := player.skill_manager.get_data_by_action(action_name)
	skill_slots[slot_index].set_skill_data(data)

# ========================== 界面更新方法模块 ==========================
## 功能：更新生命值显示（数值文本 + 进度条）。
func update_health_display():
	health_label.text = "HP: %s/%s" % [current_health, max_health]
	health_bar.max_value = max_health
	health_bar.value = current_health

## 功能：更新能量值显示（数值文本 + 进度条）。
func update_energy_display():
	energy_label.text = "MP: %s/%s" % [current_energy, max_energy]
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy

## 功能：更新连击数显示。
func update_combo_display():
	combo_label.text = "Combo: %s" % current_combo

## 功能：重置 HUD 状态（玩家复活或进入新关卡时调用）。
## 说明：重置 HP/MP/连击数显示，重新初始化技能槽图标，清除所有冷却状态。
func reset_hud():
	current_health = max_health
	current_energy = max_energy
	current_combo = 0
	update_health_display()
	update_energy_display()
	update_combo_display()
	# 重新初始化技能槽图标
	_init_skill_slot_icons()
	# 清除所有技能槽的冷却显示
	for i in range(skill_slots.size()):
		skill_slots[i].hide_cooldown()

# ========================== UI 按钮回调模块 ==========================
## 功能：暂停按钮被点击时，通知 UIManager 打开暂停菜单。
func _on_pause_button_pressed():
	UIManager.open_pause_menu()

## 功能：技能槽被鼠标点击时，通过 EventBus 通知 Player 释放技能。
## 参数：slot_index (int) - 被点击的技能槽索引
func _on_skill_slot_clicked(slot_index: int) -> void:
	EventBus.skill_slot_clicked.emit(slot_index)

# ========================== 输入回调模块 ==========================
## 功能：键盘输入触发动作时闪烁对应技能槽。
## 说明：纯视觉反馈，不涉及技能释放逻辑，技能释放由 input_handler -> player_state_machine 处理。
## 参数：action (String) - 动作名称（如 "skill_1"）
func _on_input_action_triggered(action: String) -> void:
	var slot_index: int = SKILL_ACTION_TO_SLOT.get(action, -1)
	if slot_index >= 0 and slot_index < skill_slots.size():
		skill_slots[slot_index].flash_pressed()

# ========================== 冷却回调模块 ==========================
## 功能：收到技能冷却进度更新时，直接更新对应技能槽的冷却显示。
## 说明：冷却倒计时计算由 SkillRunner 在技能系统中完成，HUD 仅做展示转发。
## 参数：slot_index (int) - 技能槽索引；remaining (float) - 剩余冷却秒数；total (float) - 总冷却秒数
func _on_skill_cooldown_updated(slot_index: int, remaining: float, total: float) -> void:
	if slot_index < 0 or slot_index >= skill_slots.size():
		return
	skill_slots[slot_index].update_cooldown(remaining, total)

## 功能：收到技能冷却结束时清除对应技能槽的冷却显示。
## 参数：slot_index (int) - 技能槽索引
func _on_skill_cooldown_finished(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= skill_slots.size():
		return
	skill_slots[slot_index].hide_cooldown()

# ========================== 全局信号回调模块 ==========================
## 功能：生命值变化时更新本地状态和显示。
## 参数：new_health (int) - 当前生命值；new_max_health (int) - 最大生命值
func _on_health_updated(new_health: int, new_max_health: int):
	current_health = new_health
	max_health = new_max_health
	update_health_display()

## 功能：能量值变化时更新本地状态和显示。
## 参数：new_energy (int) - 当前能量值；new_max_energy (int) - 最大能量值
func _on_energy_updated(new_energy: int, new_max_energy: int):
	current_energy = new_energy
	max_energy = new_max_energy
	update_energy_display()

## 功能：连击数变化时更新本地状态和显示。
## 参数：new_combo (int) - 当前连击数
func _on_combo_updated(new_combo: int):
	current_combo = new_combo
	update_combo_display()

## 功能：金币数量增加时更新显示。
## 参数：amount (int) - 本次增加的金币数量
func _on_coin_collected(amount: int) -> void:
	coin_count += amount
	coin_label.text = str(coin_count)

# ========================== 玩家就绪回调模块 ==========================
## 功能：Player 初始化完成时延迟初始化技能槽图标。
## 说明：用于 player_ready 信号晚于 HUD._ready() 触发的时序场景，
##       确保 Global.player 已非 null 后再读取技能数据。
func _on_player_ready() -> void:
	_init_skill_slot_icons()

# ==============================================================================
#   HUD.gd
#   功能：游戏主界面 HUD，显示玩家生命值、能量值、连击数、金币数量、
#        技能快捷栏（图标、按下反馈、冷却遮罩）等信息。
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

## 各技能槽的冷却剩余时间追踪（0 = 无冷却）
var _slot_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]

## 各技能槽的总冷却时间（用于计算比例）
var _slot_cooldown_totals: Array[float] = [0.0, 0.0, 0.0, 0.0]

# ========================== 生命周期模块 ==========================
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

	# 连接技能冷却信号
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

	# 初始化技能槽图标（兼容 Player 已就绪和尚未就绪两种时序）
	if EventBus.player_ready.is_connected(_on_player_ready):
		EventBus.player_ready.disconnect(_on_player_ready)
	EventBus.player_ready.connect(_on_player_ready)
	
	if Global.player != null:
		_init_skill_slot_icons()

func _exit_tree() -> void:
	# 断开全局信号连接
	EventBus.health_updated.disconnect(_on_health_updated)
	EventBus.energy_updated.disconnect(_on_energy_updated)
	EventBus.combo_updated.disconnect(_on_combo_updated)
	EventBus.coin_collected.disconnect(_on_coin_collected)
	EventBus.skill_cooldown_updated.disconnect(_on_skill_cooldown_updated)
	EventBus.skill_cooldown_finished.disconnect(_on_skill_cooldown_finished)
	EventBus.skill_slot_changed.disconnect(_on_skill_slot_changed)
	
	if EventBus.player_ready.is_connected(_on_player_ready):
		EventBus.player_ready.disconnect(_on_player_ready)
	if InputManager.has_signal("action_triggered") and InputManager.action_triggered.is_connected(_on_input_action_triggered):
		InputManager.action_triggered.disconnect(_on_input_action_triggered)

func _process(delta: float) -> void:
	# 每帧更新技能冷却显示（对于在冷却中的槽位）
	for i in range(_slot_cooldowns.size()):
		if _slot_cooldowns[i] > 0.0:
			_slot_cooldowns[i] = maxf(0.0, _slot_cooldowns[i] - delta)
			if _slot_cooldowns[i] <= 0.0:
				_slot_cooldowns[i] = 0.0
				skill_slots[i].hide_cooldown()
			else:
				skill_slots[i].update_cooldown(_slot_cooldowns[i], _slot_cooldown_totals[i])

# ========================== 技能槽初始化模块 ==========================
## 功能：从 Global.player 获取技能数据，初始化 4 个技能槽的图标
func _init_skill_slot_icons() -> void:
	if not Global.player:
		return
	var player := Global.player as Player
	for i in range(skill_slots.size()):
		var action_name := "skill_%d" % [i + 1]
		var data := player.get_skill_data_by_action(action_name)
		skill_slots[i].set_skill_data(data)
		skill_slots[i].hide_cooldown()

# ========================== 技能槽变更响应模块 ==========================
## 功能：当玩家更换技能时，更新对应技能槽的图标显示
## 参数：slot_index (int) - 技能槽索引（0 ~ 3）
func _on_skill_slot_changed(slot_index: int) -> void:
	if not Global.player:
		return
	if slot_index < 0 or slot_index >= skill_slots.size():
		return
	var player := Global.player as Player
	var action_name := "skill_%d" % [slot_index + 1]
	var data := player.get_skill_data_by_action(action_name)
	skill_slots[slot_index].set_skill_data(data)

# ========================== 界面更新方法模块 ==========================
func update_health_display():
	health_label.text = "HP: %s/%s" % [current_health, max_health]
	health_bar.max_value = max_health
	health_bar.value = current_health

func update_energy_display():
	energy_label.text = "MP: %s/%s" % [current_energy, max_energy]
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy

func update_combo_display():
	combo_label.text = "Combo: %s" % current_combo

## 功能：重置 HUD 状态（玩家复活或进入新关卡时调用）
func reset_hud():
	current_health = max_health
	current_energy = max_energy
	current_combo = 0
	update_health_display()
	update_energy_display()
	update_combo_display()
	# 重新初始化技能槽图标
	_init_skill_slot_icons()
	# 清空所有冷却
	for i in range(_slot_cooldowns.size()):
		_slot_cooldowns[i] = 0.0
		_slot_cooldown_totals[i] = 0.0
		skill_slots[i].hide_cooldown()

# ========================== UI 按钮回调模块 ==========================
func _on_pause_button_pressed():
	UIManager.open_pause_menu()

## 功能：技能槽被鼠标点击时，通过 EventBus 通知 Player 释放技能
func _on_skill_slot_clicked(slot_index: int) -> void:
	EventBus.skill_slot_clicked.emit(slot_index)

# ========================== 输入回调模块 ==========================
## 功能：键盘输入触发动作时闪烁对应技能槽
## 参数：action (String) - 动作名称（如 "skill_1"）
func _on_input_action_triggered(action: String) -> void:
	var slot_index: int = SKILL_ACTION_TO_SLOT.get(action, -1)
	if slot_index >= 0 and slot_index < skill_slots.size():
		skill_slots[slot_index].flash_pressed()

# ========================== 冷却回调模块 ==========================
## 功能：收到技能冷却进度更新时记录到本地追踪数组
func _on_skill_cooldown_updated(slot_index: int, remaining: float, total: float) -> void:
	if slot_index < 0 or slot_index >= _slot_cooldowns.size():
		return
	_slot_cooldowns[slot_index] = remaining
	_slot_cooldown_totals[slot_index] = total

## 功能：收到技能冷却结束时清除本地记录并隐藏冷却显示
func _on_skill_cooldown_finished(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_cooldowns.size():
		return
	_slot_cooldowns[slot_index] = 0.0
	_slot_cooldown_totals[slot_index] = 0.0
	skill_slots[slot_index].hide_cooldown()

# ========================== 全局信号回调模块 ==========================
func _on_health_updated(new_health: int, new_max_health: int):
	current_health = new_health
	max_health = new_max_health
	update_health_display()

func _on_energy_updated(new_energy: int, new_max_energy: int):
	current_energy = new_energy
	max_energy = new_max_energy
	update_energy_display()

func _on_combo_updated(new_combo: int):
	current_combo = new_combo
	update_combo_display()

func _on_coin_collected(amount: int) -> void:
	coin_count += amount
	coin_label.text = str(coin_count)

# ========================== 玩家就绪回调模块 ==========================
## 功能：Player 初始化完成时初始化技能槽图标（延迟初始化）
func _on_player_ready() -> void:
	_init_skill_slot_icons()

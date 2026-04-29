# ==============================================================================
#   AttackComponent.gd
#   功能：攻击组件，管理攻击判定帧、连携窗口以及缓冲输入，提供攻击开始/结束、
#        连携窗口控制、判定帧查询等核心逻辑。
# ==============================================================================
extends Node
class_name AttackComponent

# ========================== 信号声明模块 ==========================
## 触发时机：每次攻击开始时（start_attack 调用后立即触发）
## 参数：attack_id (String) - 攻击标识，如 "light_1"；damage_multiplier (float) - 伤害倍率
signal attack_performed(attack_id: String, damage_multiplier: float)

# ========================== 导出变量模块 ==========================
## 连携窗口持续时间（秒），在此期间可以衔接下一次攻击
@export var combo_window_duration: float = 0.3
## 攻击判定帧持续时间（秒），在此期间伤害计算有效
@export var hit_window_duration: float = 0.1

# ========================== 内部变量模块 ==========================
## 是否正在攻击中
var _is_attacking: bool = false
## 连携窗口是否激活
var _combo_window_active: bool = false
## 判定帧窗口是否激活
var _hit_window_active: bool = false
## 当前攻击的唯一标识
var _current_attack_id: String = ""
## 当前攻击的伤害倍率
var _current_damage_multiplier: float = 1.0

# ========================== 节点引用模块 ==========================
## 连携窗口计时器节点（需在场景树中命名为 ComboTimer）
@onready var combo_timer: Timer = $ComboTimer
## 判定帧计时器节点（需在场景树中命名为 HitTimer）
@onready var hit_timer: Timer = $HitTimer

# ========================== 公共 API 模块 ==========================
## 功能：开始一次攻击（通常由动画事件或输入响应调用）
## 参数：attack_id (String) - 攻击标识；damage_multiplier (float) - 伤害倍率，默认为 1.0
func start_attack(attack_id: String, damage_multiplier: float = 1.0) -> void:
	if _is_attacking:
		# 已处于攻击中，可根据设计决定是否允许打断（这里简单返回）
		return
	_is_attacking = true
	_current_attack_id = attack_id
	_current_damage_multiplier = damage_multiplier
	
	# 启动判定帧定时器
	if hit_timer.is_stopped():
		hit_timer.start(hit_window_duration)
		_hit_window_active = true
	
	# 发射攻击信号（可在判定帧开始时或立即，根据设计）
	attack_performed.emit(attack_id, damage_multiplier)
	print("[AttackComponent] 攻击开始: ", attack_id)

## 功能：结束当前攻击（由动画结束事件或判定帧结束后调用）
func end_attack() -> void:
	if not _is_attacking:
		return
	_is_attacking = false
	_hit_window_active = false
	hit_timer.stop()
	# 确保连携窗口也被关闭
	_combo_window_active = false
	combo_timer.stop()
	print("[AttackComponent] 攻击结束")

## 功能：开启连携窗口（通常在攻击动画的后半段或判定帧结束后调用）
func open_combo_window() -> void:
	if not _is_attacking:
		return
	if _combo_window_active:
		return
	_combo_window_active = true
	combo_timer.start(combo_window_duration)
	print("[AttackComponent] 连携窗口开启，持续时间: ", combo_window_duration)

## 功能：手动关闭连携窗口（也可由定时器自动关闭）
func close_combo_window() -> void:
	if _combo_window_active:
		_combo_window_active = false
		combo_timer.stop()
		print("[AttackComponent] 连携窗口关闭")

## 功能：检查当前是否允许发动下一次攻击或技能（即是否处于连携窗口内）
## 返回值：bool - true 表示允许连击
func can_perform_next_attack() -> bool:
	return _combo_window_active

## 功能：检查是否在判定帧内（用于伤害计算，可选）
## 返回值：bool - true 表示判定帧窗口已激活
func is_hit_window_active() -> bool:
	return _hit_window_active

## 功能：尝试在连携窗口内执行一次攻击（通常与 InputManager 配合）
## 参数：attack_id (String) - 攻击标识；damage_multiplier (float) - 伤害倍率，默认为 1.0
## 返回值：bool - true 表示成功触发本次攻击
func try_perform_buffered_attack(attack_id: String, damage_multiplier: float = 1.0) -> bool:
	if can_perform_next_attack() and not _is_attacking:
		start_attack(attack_id, damage_multiplier)
		return true
	return false

# ========================== 内部回调模块 ==========================
## 功能：连携窗口计时器超时时的回调（需手动连接 Timer.timeout 信号）
## 说明：此函数不会自动连接，请在 _ready() 或编辑器中将 ComboTimer.timeout 连接到本函数
func _on_combo_timer_timeout() -> void:
	_combo_window_active = false
	print("[AttackComponent] 连携窗口超时关闭")

## 功能：判定帧计时器超时时的回调（需手动连接 Timer.timeout 信号）
## 说明：此函数不会自动连接，请在 _ready() 或编辑器中将 HitTimer.timeout 连接到本函数
## TODO: 判定帧结束后自动结束攻击？根据设计，也可以让动画结束信号调用 end_attack
##       目前不自动 end_attack，留给外部调用决定
func _on_hit_timer_timeout() -> void:
	_hit_window_active = false
	print("[AttackComponent] 判定帧结束")

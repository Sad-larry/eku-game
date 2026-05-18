# ==============================================================================
#   status_effect_instance.gd
#   功能：状态效果运行时实例。每个正在生效的效果对应一个 Instance，
#        持有剩余时间、当前层数、策略引用等运行时状态。
# ==============================================================================
class_name StatusEffectInstance extends RefCounted

# ========================== 属性 ==========================
## 关联的效果类型定义
var effect_type: StatusEffectType
## 施加来源（可为 null）
var source: Node2D
## 当前叠加层数
var stacks: int = 1
## 剩余持续时间（秒）
var remaining_duration: float
## 距下次 tick 的计时器
var tick_timer: float = 0.0
## 策略实例（由 effect_type.strategy_script 实例化）
var strategy: StatusEffectStrategy
## 用户自定义数据（策略可在此存储运行时状态）
var user_data: Dictionary = {}

# ========================== 初始化 ==========================
## 功能：从效果类型创建运行时实例
## 参数：type - 效果类型定义，src - 施加来源
func _init(type: StatusEffectType, src: Node2D = null) -> void:
	effect_type = type
	source = src
	remaining_duration = type.duration
	tick_timer = type.tick_interval
	if type.strategy_script:
		strategy = type.strategy_script.new()

# ========================== 公共 API ==========================
## 功能：获取效果 ID（代理 effect_type.id）
func get_id() -> String:
	return effect_type.id

## 功能：效果是否已过期（duration 为 0 表示永久效果，永不过期）
func is_expired() -> bool:
	if effect_type.duration <= 0.0:
		return false
	return remaining_duration <= 0.0

## 功能：是否到了执行 tick 的时间
func should_tick() -> bool:
	return tick_timer <= 0.0

## 功能：重置 tick 计时器
func reset_tick_timer() -> void:
	tick_timer = effect_type.tick_interval

## 功能：尝试增加层数，返回是否成功（未达上限）
func try_add_stack() -> bool:
	if stacks < effect_type.max_stacks:
		stacks += 1
		return true
	return false

## 功能：刷新持续时间至初始值
func refresh_duration() -> void:
	remaining_duration = effect_type.duration

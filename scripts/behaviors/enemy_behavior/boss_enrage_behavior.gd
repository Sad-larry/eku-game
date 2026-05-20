# ==============================================================================
#   boss_enrage_behavior.gd
#   功能：Boss狂暴行为。进入狂暴状态，提升属性，持续一段时间后恢复。
# ==============================================================================
class_name BossEnrageBehavior extends TriggerableBehavior

## 狂暴持续时间（秒）
@export var enrage_duration: float = 10.0

## 伤害提升倍率
@export var damage_boost: float = 1.5

## 移速提升倍率
@export var speed_boost: float = 1.3

## 是否正在狂暴
var _is_enraged: bool = false

## 狂暴计时器
var _enrage_timer: float = 0.0

## 原始属性备份
var _original_damage: float = 0.0
var _original_speed: float = 0.0

# ========================== 生命周期 ==========================
func _on_update(delta: float) -> void:
	super._on_update(delta)
	# 狂暴持续时间管理
	if _is_enraged:
		_enrage_timer -= delta
		if _enrage_timer <= 0.0:
			_end_enrage()

# ========================== 行为执行 ==========================
func _execute_behavior() -> void:
	if _is_enraged or enemy == null:
		return
	_start_enrage()

func _start_enrage() -> void:
	_is_enraged = true
	_enrage_timer = enrage_duration

	# 备份原始属性
	if enemy.stats_resource:
		_original_damage = float(enemy.stats_resource.damage)
		_original_speed = enemy.stats_resource.speed

	# 应用狂暴加成
	if enemy.stats_resource:
		enemy.stats_resource.damage = int(enemy.stats_resource.damage * damage_boost)
		enemy.stats_resource.speed *= speed_boost

	_apply_enrage_visual()

	if Global.DEBUG_MODE:
		print("[BossEnrageBehavior] 进入狂暴状态")

func _end_enrage() -> void:
	_is_enraged = false

	# 恢复原始属性
	if enemy and enemy.stats_resource:
		enemy.stats_resource.damage = int(_original_damage)
		enemy.stats_resource.speed = _original_speed

	_remove_enrage_visual()

	if Global.DEBUG_MODE:
		print("[BossEnrageBehavior] 狂暴状态结束")

func _apply_enrage_visual() -> void:
	# TODO: 应用狂暴视觉效果
	if enemy.anim_controller and enemy.anim_controller.sprite:
		enemy.anim_controller.sprite.modulate = Color(1.5, 0.2, 0.2, 1)

func _remove_enrage_visual() -> void:
	# TODO: 移除狂暴视觉效果
	if enemy.anim_controller and enemy.anim_controller.sprite:
		enemy.anim_controller.sprite.modulate = Color.WHITE

func _on_cleanup() -> void:
	if _is_enraged:
		_end_enrage()

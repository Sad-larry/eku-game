# ==============================================================================
#   boss_fullscreen_behavior.gd
#   功能：Boss全屏攻击行为。对整个竞技场造成伤害。
# ==============================================================================
class_name BossFullscreenBehavior extends TriggerableBehavior

## 攻击伤害
@export var attack_damage: float = 20.0

## 预警时间（秒）
@export var warning_duration: float = 2.0

## 攻击范围（半径）
@export var attack_radius: float = 500.0

## 是否正在预警/攻击
var _is_casting: bool = false
var _cast_timer: float = 0.0
var _attack_executed: bool = false

# ========================== 生命周期 ==========================
func _on_update(delta: float) -> void:
	super._on_update(delta)
	# 施法过程管理
	if _is_casting:
		_cast_timer -= delta
		if _cast_timer <= 0.0 and not _attack_executed:
			_execute_attack()
		if _cast_timer <= -0.5:
			_is_casting = false

# ========================== 行为执行 ==========================
func _execute_behavior() -> void:
	if _is_casting or enemy == null:
		return
	_is_casting = true
	_cast_timer = warning_duration
	_attack_executed = false
	_show_warning()

func _show_warning() -> void:
	# TODO: 显示全屏预警效果
	if Global.DEBUG_MODE:
		print("[BossFullscreenBehavior] 全屏攻击预警")

func _execute_attack() -> void:
	_attack_executed = true

	# 对范围内所有玩家造成伤害
	var players := enemy.get_tree().get_nodes_in_group("player")
	for player in players:
		if player is Player:
			var distance: float = player.global_position.distance_to(enemy.global_position)
			if distance <= attack_radius:
				_apply_damage(player)

	_play_attack_effect()

	if Global.DEBUG_MODE:
		print("[BossFullscreenBehavior] 全屏攻击执行")

func _apply_damage(target: Node2D) -> void:
	var damage_calculator := DamageCalculator.new()
	var damage_info := damage_calculator.calculate(
		attack_damage, 1.0, 0.0, 1.0
	)
	if target.has_method("take_damage"):
		target.take_damage(damage_info.final_damage)

func _play_attack_effect() -> void:
	# TODO: 播放全屏攻击特效
	pass

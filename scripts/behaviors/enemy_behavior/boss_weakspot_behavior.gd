# ==============================================================================
#   boss_weakspot_behavior.gd
#   功能：Boss弱点暴露行为。暴露弱点，受到额外伤害。
# ==============================================================================
class_name BossWeakspotBehavior extends TriggerableBehavior

## 弱点持续时间（秒）
@export var weakspot_duration: float = 5.0

## 弱点受到的伤害倍率
@export var damage_multiplier: float = 2.0

## 弱点位置偏移
@export var weakspot_offset: Vector2 = Vector2(0, -50)

## 弱点碰撞体大小
@export var weakspot_radius: float = 30.0

## 是否已暴露弱点
var _weakspot_exposed: bool = false

## 弱点计时器
var _weakspot_timer: float = 0.0

## 弱点区域
var _weakspot_area: Area2D

# ========================== 生命周期 ==========================
func _on_update(delta: float) -> void:
	super._on_update(delta)
	# 弱点持续时间管理
	if _weakspot_exposed:
		_weakspot_timer -= delta
		if _weakspot_timer <= 0.0:
			_hide_weakspot()

# ========================== 行为执行 ==========================
func _execute_behavior() -> void:
	if _weakspot_exposed or enemy == null:
		return
	_expose_weakspot()

func _expose_weakspot() -> void:
	_weakspot_exposed = true
	_weakspot_timer = weakspot_duration
	_create_weakspot_area()
	_show_weakspot_visual()

	if Global.DEBUG_MODE:
		print("[BossWeakspotBehavior] 弱点暴露")

func _create_weakspot_area() -> void:
	_weakspot_area = Area2D.new()
	enemy.add_child(_weakspot_area)
	_weakspot_area.position = weakspot_offset

	var collision := CollisionShape2D.new()
	_weakspot_area.add_child(collision)
	var shape := CircleShape2D.new()
	shape.radius = weakspot_radius
	collision.shape = shape

	_weakspot_area.collision_layer = 0
	_weakspot_area.collision_mask = 0
	_weakspot_area.area_entered.connect(_on_weakspot_hit)

func _on_weakspot_hit(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		_apply_weakspot_damage(area)

func _apply_weakspot_damage(hitbox: Area2D) -> void:
	var original_damage: float = hitbox.get("damage") if hitbox.get("damage") else 0.0
	var boosted_damage: float = original_damage * damage_multiplier

	if enemy.has_method("take_damage"):
		enemy.take_damage(boosted_damage)

	_play_weakspot_hit_effect()

	if Global.DEBUG_MODE:
		print("[BossWeakspotBehavior] 弱点受到额外伤害: ", boosted_damage)

func _hide_weakspot() -> void:
	_weakspot_exposed = false
	if _weakspot_area and is_instance_valid(_weakspot_area):
		_weakspot_area.queue_free()
		_weakspot_area = null
	_hide_weakspot_visual()

	if Global.DEBUG_MODE:
		print("[BossWeakspotBehavior] 弱点消失")

func _show_weakspot_visual() -> void:
	# TODO: 显示弱点视觉标记
	pass

func _hide_weakspot_visual() -> void:
	# TODO: 隐藏弱点视觉标记
	pass

func _play_weakspot_hit_effect() -> void:
	# TODO: 播放弱点受击特效
	pass

func _on_cleanup() -> void:
	if _weakspot_exposed:
		_hide_weakspot()

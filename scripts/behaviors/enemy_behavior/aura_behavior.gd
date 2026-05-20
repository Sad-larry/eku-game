# ==============================================================================
#   aura_behavior.gd
#   功能：光环行为。持续对周围敌人造成伤害。
# ==============================================================================
extends TriggerableBehavior
class_name AuraBehavior

# ========================== 导出变量 ==========================
## 光环半径（像素）
@export var aura_radius: float = 80.0

## 每次伤害值
@export var damage_per_tick: int = 1

## 是否也影响友军
@export var friendly_fire: bool = false

# ========================== 内部变量 ==========================
var _aura_area: Area2D = null

# ========================== 生命周期 ==========================
func _on_setup() -> void:
	# 创建光环 Area2D
	_aura_area = Area2D.new()
	_aura_area.name = "AuraArea"
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = aura_radius
	collision.shape = circle
	_aura_area.add_child(collision)

	_aura_area.collision_layer = 0
	_aura_area.collision_mask = 4

	enemy.add_child(_aura_area)

func _execute_behavior() -> void:
	if _aura_area == null:
		return

	var hurtboxes: Array[Area2D] = _aura_area.get_overlapping_areas()
	for area in hurtboxes:
		var hurtbox := area as HurtboxComponent
		if hurtbox == null:
			continue
		var damage_event := {
			"damage": damage_per_tick,
			"source": enemy,
			"target": hurtbox.owner,
			"skill": null
		}
		EventBus.skill_damage_requested.emit(damage_event)

func _on_cleanup() -> void:
	if _aura_area and _aura_area.get_parent():
		_aura_area.queue_free()

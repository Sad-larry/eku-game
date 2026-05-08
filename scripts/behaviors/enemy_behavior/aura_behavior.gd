# ==============================================================================
#   aura_behavior.gd
#   功能：精英光环行为。持续对周围敌人或玩家造成伤害/减速效果。
#        通常挂在精英怪（elite 标签）身上。
# ==============================================================================
extends EnemyBehavior
class_name AuraBehavior

# ========================== 导出变量模块 ==========================
## 光环半径（像素）
@export var aura_radius: float = 80.0

## 伤害间隔（秒），每多少秒造成一次伤害
@export var damage_interval: float = 1.0

## 每次伤害值
@export var damage_per_tick: int = 1

## 是否也影响友军（误伤）
@export var friendly_fire: bool = false

# ========================== 内部变量模块 ==========================
var _tick_timer: float = 0.0

## 光环碰撞形状的引用
var _aura_area: Area2D = null

# ========================== 生命周期模块 ==========================
func _on_setup() -> void:
	# 创建光环 Area2D
	_aura_area = Area2D.new()
	_aura_area.name = "AuraArea"
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = aura_radius
	collision.shape = circle
	_aura_area.add_child(collision)
	
	# 设置碰撞层（仅在 aura_layer 检测）
	_aura_area.collision_layer = 0
	_aura_area.collision_mask = 4  # 匹配 Hurtbox 的 layer
	
	enemy.add_child(_aura_area)

func _on_update(delta: float) -> void:
	_tick_timer += delta
	if _tick_timer < damage_interval:
		return
	_tick_timer = 0.0
	
	# 获取光环范围内的所有受击框
	var hurtboxes: Array[Area2D] = _aura_area.get_overlapping_areas()
	for area in hurtboxes:
		var hurtbox := area as HurtboxComponent
		if hurtbox == null:
			continue
		# 通过 EventBus 造成伤害
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

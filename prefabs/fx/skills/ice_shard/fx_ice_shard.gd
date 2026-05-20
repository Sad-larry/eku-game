# ==============================================================================
#   fx_ice_shard.gd
#   功能：冰锥术特效。发射冰锥，对命中的敌人造成伤害并减速。
# ==============================================================================
extends FxBoot

## 冰锥飞行速度
@export var speed: float = 400.0

## 减速效果持续时间
@export var slow_duration: float = 2.0

## 减速比例
@export var slow_ratio: float = 0.5

func _ready() -> void:
	super._ready()
	# 冰锥术：向前方飞行
	_setup_projectile()

func _setup_projectile() -> void:
	# 设置飞行方向
	var direction := Vector2.RIGHT.rotated(global_rotation)
	velocity = direction * speed

func _on_hit(target: Node2D) -> void:
	super._on_hit(target)
	# 施加减速效果
	if target.has_method("apply_status_effect"):
		target.apply_status_effect("slow", slow_duration, slow_ratio)

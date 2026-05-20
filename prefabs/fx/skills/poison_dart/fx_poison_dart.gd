# ==============================================================================
#   fx_poison_dart.gd
#   功能：毒镖特效。投掷毒镖，对命中的敌人造成持续伤害。
# ==============================================================================
extends FxBoot

## 毒镖飞行速度
@export var speed: float = 350.0

## 毒素持续时间
@export var poison_duration: float = 3.0

## 毒素每秒伤害
@export var poison_damage_per_second: float = 3.0

func _ready() -> void:
	super._ready()
	_setup_projectile()

func _setup_projectile() -> void:
	var direction := Vector2.RIGHT.rotated(global_rotation)
	velocity = direction * speed

func _on_hit(target: Node2D) -> void:
	super._on_hit(target)
	# 施加中毒效果
	if target.has_method("apply_status_effect"):
		target.apply_status_effect("poison", poison_duration, poison_damage_per_second)

# ==============================================================================
#   fx_wind_blade.gd
#   功能：风刃特效。发射风刃，穿透敌人造成伤害。
# ==============================================================================
extends FxBoot

## 风刃飞行速度
@export var speed: float = 500.0

## 穿透次数（-1为无限穿透）
@export var pierce_count: int = 3

## 已穿透计数
var _pierced: int = 0

func _ready() -> void:
	super._ready()
	_setup_projectile()

func _setup_projectile() -> void:
	var direction := Vector2.RIGHT.rotated(global_rotation)
	velocity = direction * speed

func _on_hit(target: Node2D) -> void:
	super._on_hit(target)
	_pierced += 1
	# 达到穿透次数后销毁
	if pierce_count >= 0 and _pierced >= pierce_count:
		queue_free()

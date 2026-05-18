# ==============================================================================
#   hidden_wall.gd
#   功能：可破坏隐藏墙。攻击 3 次后破坏，暴露隐藏房间。
# ==============================================================================
extends StaticBody2D
class_name HiddenWall

## 需要被攻击的次数
@export var hits_required: int = 3

@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var _hits_taken: int = 0

func _ready() -> void:
	# 半透明视觉提示
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.4)
	hurtbox.damaged.connect(_on_damaged)

func _on_damaged(_hitbox: HitboxComponent) -> void:
	_hits_taken += 1

	# 视觉反馈：越来越不透明
	if sprite:
		var alpha := 0.4 + (float(_hits_taken) / hits_required) * 0.6
		sprite.modulate = Color(1, 1, 1, alpha)

	if _hits_taken >= hits_required:
		_destroy()

func _destroy() -> void:
	# 发送隐藏房间揭露信号
	var coord := Vector2i.ZERO
	EventBus.hidden_room_revealed.emit(coord)

	# 破坏动画
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

	if Global.DEBUG_MODE:
		print("[HiddenWall] 隐藏墙已破坏")

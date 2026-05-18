# ==============================================================================
#   trap_base.gd
#   功能：陷阱基类。Area2D 检测玩家进入后触发伤害/效果，
#        支持触发间隔防止连击。
# ==============================================================================
extends Area2D
class_name TrapBase

# ========================== 导出变量 ==========================
## 基础伤害值
@export var base_damage: int = 3
## 触发间隔（秒），防止单帧内重复触发
@export var trigger_cooldown: float = 1.0
## 关联的状态效果类型（可选，DOT/减速/眩晕等）
@export var status_effect: StatusEffectType

# ========================== 节点引用 ==========================
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ========================== 状态变量 ==========================
var _can_trigger: bool = true
var _ring: int = 0

# ========================== 生命周期 ==========================
func _ready() -> void:
	body_entered.connect(_on_body_entered)

# ========================== 公共 API ==========================
## 功能：设置陷阱环数（由 Spawner 调用）
func setup(ring: int) -> void:
	_ring = ring

## 功能：计算实际伤害 = 基础值 + 环数 * 2
func get_damage() -> int:
	return base_damage + _ring * 2

# ========================== 触发逻辑 ==========================
func _on_body_entered(body: Node2D) -> void:
	if not _can_trigger:
		return
	if not body is Player:
		return

	_can_trigger = false

	# 造成伤害
	var player := body as Player
	if player.health_component:
		player.health_component.take_damage(get_damage())

	# 施加状态效果（如果有）
	if status_effect and player.status_effect_component:
		player.status_effect_component.apply_effect(status_effect, self)

	# 视觉反馈
	_on_triggered()

	# 冷却恢复
	await get_tree().create_timer(trigger_cooldown).timeout
	_can_trigger = true

## 功能：陷阱触发时的视觉反馈（子类可覆写）
func _on_triggered() -> void:
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

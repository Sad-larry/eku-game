# ==============================================================================
#   enemy_projectile.gd
#   功能：敌人投射物，沿指定方向飞行，碰撞到玩家后造成伤害并自行销毁。
# ==============================================================================
extends Area2D
class_name EnemyProjectile

# ========================== 导出变量模块 ==========================
## 飞行速度（像素/秒）
@export var speed: float = 200.0
## 生存时间（秒），超时后自动销毁
@export var lifetime: float = 5.0
## 伤害值
@export var damage: int = 10

# ========================== 节点引用模块 ==========================
@onready var hitbox_component: HitboxComponent = $HitboxComponent

# ========================== 内部变量模块 ==========================
## 飞行方向（归一化）
var _direction: Vector2 = Vector2.RIGHT
## 已存活时间
var _age: float = 0.0

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	hitbox_component.disable()

## 功能：每帧更新位置和生命周期
func _process(delta: float) -> void:
	position += _direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()

# ========================== 公共 API 模块 ==========================
## 功能：发射投射物
## 参数：direction (Vector2) - 发射方向（会自动归一化）
func launch(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()
	hitbox_component.setup(damage, false, self)
	hitbox_component.enable()

# ========================== 信号回调模块 ==========================
## 功能：碰撞到物理体时销毁
func _on_body_entered(body: Node2D) -> void:
	# 碰撞到墙壁等物理体时销毁
	if body is TileMapLayer or body is StaticBody2D:
		queue_free()

## 功能：碰撞到 HurtboxComponent 时造成伤害并销毁
func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		# HurtboxComponent 会通过信号处理伤害，投射物直接销毁
		queue_free()

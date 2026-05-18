# ==============================================================================
#   coin_pickup.gd
#   功能：货币掉落实体，敌人死亡后生成，玩家接近可拾取，
#        支持弹出动画、磁吸效果和自动消失。
# ==============================================================================
extends Area2D
class_name CoinPickup

# ========================== 导出变量模块 ==========================
## 货币数据资源（配置价值、颜色等属性）
@export var coin_data: CoinData

## 磁吸移动速度（像素/秒）
@export var magnet_speed: float = 300.0

## 自动消失时间（秒）
@export var lifetime: float = 15.0

# ========================== 节点引用模块 ==========================
## 精灵节点
@onready var _sprite: Sprite2D = $Sprite2D
## 帧动画播放器
@onready var _anim: AnimationPlayer = $AnimationPlayer

# ========================== 内部变量模块 ==========================
## 是否可拾取（生成后延迟拾取，防止瞬间拾取）
var _is_collectable: bool = false

## 磁吸目标（玩家节点）
var _magnet_target: Node2D = null

## 剩余弹出动画时间
var _bounce_timer: float = 0.0

## 弹出速度向量（由 spawn 时设置）
var _velocity: Vector2 = Vector2.ZERO

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 播放帧循环动画
	_anim.play("spin")
	# 延迟 0.5 秒后才可拾取
	var delay_timer: SceneTreeTimer = get_tree().create_timer(0.5)
	delay_timer.timeout.connect(func(): _is_collectable = true)
	# 自动消失倒计时
	var despawn_timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	despawn_timer.timeout.connect(_on_lifetime_timeout)

func _physics_process(delta: float) -> void:
	# 弹出动画阶段：应用初速度并衰减
	if _bounce_timer > 0.0:
		_bounce_timer -= delta
		global_position += _velocity * delta
		_velocity = _velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		return

	# 磁吸效果：朝向玩家移动
	if _magnet_target and is_instance_valid(_magnet_target):
		var direction: Vector2 = (_magnet_target.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta

# ========================== 公共 API 模块 ==========================
## 功能：初始化货币并以指定方向和力度弹出
## 参数：data (CoinData) - 货币数据；direction (Vector2) - 弹出方向；force (float) - 弹出力度
func spawn(data: CoinData, direction: Vector2, force: float) -> void:
	coin_data = data
	_velocity = direction.normalized() * force
	_bounce_timer = 0.3
	# 设置精灵纹理（帧动画由 AnimationPlayer 自动驱动）
	if coin_data and _sprite:
		_sprite.texture = coin_data.icon
		_sprite.hframes = coin_data.hframes

# ========================== 信号回调模块 ==========================
## 功能：当玩家进入拾取范围时触发收集
## 参数：body (Node2D) - 进入区域的实体
func _on_body_entered(body: Node2D) -> void:
	if not _is_collectable:
		return
	if not body.is_in_group("player"):
		return
	_collect()

## 功能：生命周期超时回调，淡出后销毁
func _on_lifetime_timeout() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

# ========================== 内部方法模块 ==========================
## 功能：执行收集逻辑（增加货币、发射信号、显示飘字、播放音效、销毁自身）
func _collect() -> void:
	if coin_data == null:
		push_warning("[CoinPickup] coin_data 未设置，跳过收集")
		queue_free()
		return

	var amount: int = coin_data.value
	# 增加货币到 CurrencyManager
	CurrencyManager.add_coin(amount)
	# 发射收集信号
	EventBus.coin_collected.emit(amount)
	# 显示飘字（如 "+1"）
	DamagePopupSpawner.show_text_at(global_position, "+%d" % amount, coin_data.color)
	# 播放拾取音效
	_play_collect_sfx()
	# 播放消失动画
	_play_collect_animation()

## 功能：播放拾取音效（音效文件路径待配置）
func _play_collect_sfx() -> void:
	# TODO: 添加音效资源后替换路径（如 "res://assets/audio/sfx_coin_collect.wav"）
	# AudioManager.play_sfx("res://assets/audio/sfx_coin_collect.wav")
	pass

## 功能：播放拾取消失动画（放大后缩放归零 + 淡出）
func _play_collect_animation() -> void:
	_is_collectable = false
	# 移除碰撞，防止重复触发
	set_deferred("monitoring", false)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_delay(0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)

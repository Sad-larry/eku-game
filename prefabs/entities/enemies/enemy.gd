# ==============================================================================
#   enemy.gd
#   功能：敌方单位核心控制器，管理生命值、状态机、动画、受击与死亡逻辑，
#        整合 HealthComponent、HurtboxComponent、状态机等子系统。
#        敌方单位的基类
# ==============================================================================
extends CharacterBody2D
class_name Enemy

# ========================== 常量定义模块 ==========================
## 货币掉落实体场景
const COIN_PICKUP_SCENE: PackedScene = preload("res://prefabs/objects/pickups/coin_pickup/coin_pickup.tscn")
## 默认掉落货币数据（铜币）
const COIN_DATA: CoinData = preload("res://resources/data/currency/coins/coin_copper.tres")

# ========================== 导出变量模块 ==========================
## 敌人属性配置资源（需包含生命值、攻击力等基础属性）
@export var stats_resource: EnemyStats
## 行为组件列表
@export var behaviors: Array[EnemyBehavior] = []

# ========================== 节点引用模块 ==========================
## 敌人状态机节点（控制巡逻、追击、攻击等行为状态）
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
## 敌人动画控制器节点（负责播放不同状态对应的动画）
@onready var anim_controller: EnemyAnimationController = %EnemyAnimationController
## 生命值组件节点（管理 HP、受伤、死亡逻辑）
@onready var health_component: HealthComponent = $StatsComponents/HealthComponent
## 血条 UI 节点（需在场景中通过 %HealBar 唯一命名）
@onready var heal_bar: HealthBar = %HealBar
## 攻击判定框组件节点
@onready var hitbox_component: HitboxComponent = $StatsComponents/HitboxComponent
## 受击判定框组件节点（接收 HitboxComponent 的伤害）
@onready var hurtbox_component: HurtboxComponent = $StatsComponents/HurtboxComponent
## 武器精灵图
@onready var weapon_sprite: Sprite2D = %WeaponSprite
## 视野区域
@onready var vision_area: Area2D = %VisionArea
## 移动组件
@onready var movement_component: EnemyMovementComponent = %EnemyMovementComponent
## 状态效果组件（管理增益、减益、DOT 等效果）
var status_effect_component: StatusEffectComponent

# ========================== 运行时状态变量 ==========================
## 玩家当前是否在视野区域内（由 VisionArea 信号更新）
var player_detected: bool = false
## 敌人的生成位置（用于限制游走范围）
var spawn_position: Vector2 = Vector2.ZERO
## 移动速度倍率（由 ChaseBehavior 等外部行为修改），默认 1.0
var speed_multiplier: float = 1.0
## 攻击范围倍率（由 ChaseBehavior 等外部行为修改），默认 1.0
var attack_range_multiplier: float = 1.0
## 是否正在被击退（击退期间禁止移动）
var _is_knocked_back: bool = false

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化各组件、连接信号并启动状态机
func _ready() -> void:
	# 记录生成位置
	spawn_position = global_position

	# 同步碰撞范围
	_sync_vision_area_range()
	_sync_hitbox_size()

	# 读取配置并初始化生命值和血条
	health_component.setup(stats_resource)
	heal_bar.setup(health_component)
	# 连接信号
	health_component.unit_died.connect(_on_died)
	# 默认禁用攻击判定框，每次攻击时临时启用
	hitbox_component.disable()
	hurtbox_component.damaged.connect(_on_hurtbox_component_damaged)

	# 根据数据设置武器显示
	if stats_resource.has_weapon:
		weapon_sprite.show()
		weapon_sprite.texture = stats_resource.weapon_texture

	# 初始化状态效果组件
	status_effect_component = StatusEffectComponent.new()
	status_effect_component.name = "StatusEffectComponent"
	add_child(status_effect_component)
	status_effect_component.setup(self)

	# 初始化行为组件
	for behavior in behaviors:
		behavior.setup(self)

	# 初始化状态机
	enemy_state_machine.init_states(self)

## 功能：每帧更新行为组件和动画朝向
func _process(_delta: float) -> void:
	# 在 _process 中更新行为组件（与状态机分开运行）
	for behavior in behaviors:
		behavior.update(_delta)

## 添加 _physics_process 来驱动翻转：
func _physics_process(_delta: float) -> void:
	anim_controller.update_flip(velocity.x)

# ========================== 内部方法模块 ==========================
## 功能：将 VisionArea 的 CollisionShape2D 半径设置为 stats 中的 detection_range
func _sync_vision_area_range() -> void:
	var collision_shape: CollisionShape2D = vision_area.get_child(0) as CollisionShape2D
	if collision_shape == null:
		return
	var circle: CircleShape2D = collision_shape.shape as CircleShape2D
	if circle == null:
		return
	circle.radius = stats_resource.detection_range

## 功能：将 Hitbox 的碰撞形状尺寸与攻击距离同步
func _sync_hitbox_size() -> void:
	var collision_shape: CollisionShape2D = hitbox_component.get_child(0) as CollisionShape2D
	if collision_shape == null:
		return
	var current_shape = collision_shape.shape

	if current_shape is RectangleShape2D:
		var new_rect: RectangleShape2D = current_shape.duplicate()
		# 宽度 = 攻击距离，高度保持不变
		new_rect.size = Vector2(get_attack_range(), current_shape.size.y)
		collision_shape.shape = new_rect
	elif current_shape is CircleShape2D:
		var new_circle: CircleShape2D = current_shape.duplicate()
		new_circle.radius = get_attack_range()
		collision_shape.shape = new_circle

# ========================== 公共 API 模块 ==========================
## 功能：执行攻击逻辑，通过 DamageCalculator 计算最终伤害
func attack() -> void:
	var result := DamageCalculator.new().calculate(
		stats_resource.damage, 1.0, stats_resource.crit_rate, stats_resource.crit_damage
	)
	hitbox_component.setup(int(result["damage"]), result["is_crit"], self)
	hitbox_component.enable()

## 功能：获取当前追击目标玩家
## 返回值：Player - 玩家实例，若未找到则返回 null
## 说明：通过组查找方式获取场景中的玩家对象
## TODO: 测试所写代码，不需要更改，后续我会自己更改（可优化为通过 RoomManager 追踪）
func get_target() -> Player:
	# MVP 阶段：通过 "player" 组查找第一个玩家
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Player
	return null

## 功能：获取检测范围（从 stats_resource 读取）
func get_detection_range() -> float:
	return stats_resource.detection_range

## 功能：返回当前有效速度（基础速度 × 倍率 × 状态效果倍率），供移动组件读取
func get_speed() -> float:
	var effect_multiplier := 1.0
	if status_effect_component:
		effect_multiplier = status_effect_component.get_speed_multiplier()
	return stats_resource.speed * speed_multiplier * effect_multiplier

## 功能：获取攻击范围（从 stats_resource 读取）
func get_attack_range() -> float:
	return stats_resource.attack_range

## 功能：受击闪红效果（持续 0.1 秒）
func flash_red() -> void:
	anim_controller.sprite.modulate = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(anim_controller.sprite):
		anim_controller.sprite.modulate = Color.WHITE

## 功能：受击击退效果（从攻击者位置推开）
## 参数：from_position (Vector2) - 攻击者位置；force (float) - 击退力度
func apply_knockback(from_position: Vector2, force: float = 200.0) -> void:
	_is_knocked_back = true
	var direction: Vector2 = (global_position - from_position).normalized()
	var target_pos: Vector2 = global_position + direction * force * 0.15
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	_is_knocked_back = false

# ========================== 信号回调模块 ==========================
## 功能：受击框受到伤害时的回调
## 参数：hitbox (HitboxComponent) - 攻击方的判定框组件，包含伤害值等信息
## 说明：若敌人已死亡则不再处理伤害，否则扣除生命值并触发状态机的 "hurt" 事件
func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	# 已死亡则不再处理伤害
	if health_component.current_health <= 0:
		return
	health_component.take_damage(hitbox.damage)
	# 记录玩家造成的伤害统计
	if hitbox.source is Player and RunManager.is_run_active():
		RunManager.record_damage_dealt(hitbox.damage)
	# 受击反馈：闪红 + 击退
	flash_red()
	if hitbox.source != null:
		apply_knockback(hitbox.source.global_position)
	enemy_state_machine.send_event("hurt")

## 功能：单位死亡时的回调
## 说明：先生成掉落货币，再触发状态机切换到 "dead" 死亡状态
func _on_died() -> void:
	_spawn_coins()
	enemy_state_machine.change_to("dead")

## 功能：在死亡位置生成 1-3 个货币，随机方向弹出
func _spawn_coins() -> void:
	var count: int = randi_range(1, 3)
	for i in count:
		var coin: CoinPickup = COIN_PICKUP_SCENE.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
		var angle: float = randf_range(0, TAU)
		coin.spawn(COIN_DATA, Vector2.from_angle(angle), randf_range(100.0, 200.0))

## 功能：玩家进入视野区域时标记 detected
func _on_vision_area_body_entered(body: Node2D) -> void:
	if body is Player:
		player_detected = true

## 功能：玩家离开视野区域时清除 detected
func _on_vision_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_detected = false

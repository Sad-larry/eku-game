# ==============================================================================
#   enemy_elite.gd
#   功能：精英敌人类。继承 Enemy 基类，应用 EliteModifier 的属性强化。
# ==============================================================================
extends Enemy
class_name EnemyElite

## 精英强化配置
@export var elite_modifier: EliteModifier

## 功能：覆写 _ready，在基础初始化后应用精英强化
func _ready() -> void:
	super._ready()
	if elite_modifier:
		_apply_modifier()

func _apply_modifier() -> void:
	# 属性倍率
	if health_component:
		health_component.max_health = int(health_component.max_health * elite_modifier.health_multiplier)
		health_component.current_health = health_component.max_health

	# 体型放大
	scale = Vector2(elite_modifier.size_scale, elite_modifier.size_scale)

	# 视觉标记
	if anim_controller and anim_controller.sprite:
		anim_controller.sprite.modulate = elite_modifier.visual_tint

	# 击杀金币倍率（通过覆写 _spawn_coins 实现）

## 功能：覆写击杀掉落，应用精英金币倍率
func _spawn_coins() -> void:
	var base_count: int = randi_range(1, 3)
	var count := int(base_count * elite_modifier.coin_multiplier) if elite_modifier else base_count
	for i in count:
		var coin: CoinPickup = COIN_PICKUP_SCENE.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
		var angle: float = randf_range(0, TAU)
		coin.spawn(COIN_DATA, Vector2.from_angle(angle), randf_range(100.0, 200.0))

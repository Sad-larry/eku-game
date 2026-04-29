# ==============================================================================
#   Enemy.gd
#   功能：敌方单位核心控制器，管理生命值、状态机、动画、受击与死亡逻辑，
#        整合 HealthComponent、HurtboxComponent、状态机等子系统。
# ==============================================================================
extends CharacterBody2D
class_name Enemy

# ========================== 导出变量模块 ==========================
## 敌人属性配置资源（需包含生命值、攻击力等基础属性）
@export var stats_resource: Resource

# ========================== 节点引用模块 ==========================
## 敌人状态机节点（控制巡逻、追击、攻击等行为状态）
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
## 敌人动画控制器节点（负责播放不同状态对应的动画）
@onready var animation_controller: EnemyAnimationController = $EnemyAnimationController
## 生命值组件节点（管理 HP、受伤、死亡逻辑）
@onready var health_component: HealthComponent = $StatsComponents/HealthComponent
## 血条 UI 节点（需在场景中通过 %HealBar 唯一命名）
@onready var heal_bar: HealthBar = %HealBar
## 受击判定框组件节点（接收 HitboxComponent 的伤害）
@onready var hurtbox_component: HurtboxComponent = $StatsComponents/HurtboxComponent

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化各组件、连接信号并启动状态机
func _ready():
	# 读取配置并初始化生命值和血条
	health_component.setup(stats_resource)
	heal_bar.setup(health_component)
	
	# 连接信号
	health_component.connect("unit_died", _on_died)
	hurtbox_component.connect("damaged", _on_hurtbox_component_damaged)
	
	# 初始化状态机（传入自身引用）
	enemy_state_machine.init_states(self)

# ========================== 公共 API 模块 ==========================
## 功能：执行攻击逻辑（实际实现可委托给 AttackComponent 或在此处直接实现）
func attack():
	# TODO: 具体攻击逻辑待实现（如检测玩家距离、触发攻击判定帧等）
	pass

## 功能：播放指定名称的动画
## 参数：anim_name (String) - 动画状态名称（如 "idle"、"walk"、"attack"）
func play_anim(anim_name: String):
	animation_controller.play_state(anim_name)

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

# ========================== 信号回调模块 ==========================
## 功能：受击框受到伤害时的回调
## 参数：hitbox (HitboxComponent) - 攻击方的判定框组件，包含伤害值等信息
## 说明：若敌人已死亡则不再处理伤害，否则扣除生命值并触发状态机的 "hurt" 事件
func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	# 已死亡则不再处理伤害
	if health_component.current_health <= 0:
		return
	health_component.take_damage(hitbox.damage)
	enemy_state_machine.send_event("hurt")

## 功能：单位死亡时的回调
## 说明：触发状态机切换到 "dead" 死亡状态（播放死亡动画、禁用碰撞等）
func _on_died():
	enemy_state_machine.change_to("dead")

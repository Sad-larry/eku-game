extends CharacterBody2D
class_name Enemy

@export var stats_resource: Resource

@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var animation_controller: EnemyAnimationController = $EnemyAnimationController
@onready var health_component: HealthComponent = $StatsComponents/HealthComponent
@onready var enemy_movement_component: EnemyMovementComponent = $EnemyMovementComponent
@onready var heal_bar: HealthBar = $StatsComponents/HealBar

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# === 配置（可从 stats_resource 读取） ===
var detection_range: float = 150.0
var attack_range: float = 30.0
var attack_cooldown: float = 1.0
var hurt_duration: float = 0.3
var speed: float = 100.0


func _ready():
	# 读取配置
	health_component.setup(stats_resource)
	heal_bar.setup(health_component)
	health_component.connect("unit_died", _on_died)
	
	# 初始化状态机
	enemy_state_machine.init_states(self)

func attack():
	# 执行攻击逻辑（委托给 AttackComponent 或直接实现）
	pass

func play_anim(anim_name: String):
	animation_controller.play_state(anim_name)
	

func _on_hurtbox_component_damaged(hitbox: HitboxComponent) -> void:
	# 已死亡则不再处理
	if health_component.current_health <= 0:
		return
	health_component.take_damage(hitbox.damage)
	enemy_state_machine.send_event("hurt")
	

func _on_died():
	enemy_state_machine.change_to("dead")

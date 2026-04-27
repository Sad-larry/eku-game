extends Node2D
class_name FxBase

# 特效需要的所有数据（由技能系统传进来）
var caster: Node2D
var target: Node2D
var target_pos: Vector2
var skill_data: SkillEffect

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 特效一实例化就自动执行生命周期
func _ready():
	# 1. 特效自己决定位置
	setup_position()
	# 2. 播放动画
	play_animation()
	# 3. 自动销毁（根据动画长度 或 固定时间）
	auto_destroy()


# ==========================
# 子类可重写 ↓
# ==========================
func setup_position():
	# 默认逻辑：子类自己覆盖这个方法！
	pass

func play_animation():
	animation_player.play("default")

func auto_destroy():
	await animation_player.finished
	queue_free()

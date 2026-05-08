# ==============================================================================
#   FxBoot.gd
#   功能：特效引导基类，作为所有视觉特效（命中特效、受击特效、技能特效等）的基类。
#        提供自动定位、动画播放、自动销毁的标准生命周期，子类可重写 setup_position
#        方法实现自定义定位逻辑（如跟随之目标、吸附到受击点等）。
# ==============================================================================
extends Node2D
class_name FxBoot

# ========================== 变量定义模块 ==========================
## 技能释放者（攻击方）节点引用（由技能系统传入）
var caster: Node2D

## 技能目标（受击方）节点引用（由技能系统传入）
var target: Node2D

## 技能目标世界坐标位置（由技能系统传入）
var target_pos: Vector2

## 技能数据资源（包含特效类型、伤害数值等）
var skill_data: SkillEffect

# ========================== 节点引用模块 ==========================
## 动画播放器节点（需在场景树中存在名为 AnimationPlayer 的子节点）
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ========================== 生命周期模块 ==========================
## 功能：特效实例化后自动执行完整生命周期：定位 -> 播动画 -> 销毁
func _ready():
	# 1. 特效自己决定位置（子类可重写）
	setup_position()
	# 2. 播放动画（子类可重写）
	play_animation()
	# 3. 自动销毁（根据动画长度）
	auto_destroy()

# ========================== 可重写方法模块 ==========================
## 功能：设置特效位置（子类可按需重写）
## 说明：默认逻辑为空，子类可根据需求实现：
##       - 跟随之目标：global_position = target.global_position
##       - 吸附到命中点：global_position = target_pos
##       - 固定偏移：global_position = target.global_position + offset
func setup_position():
	pass

## 功能：播放特效动画（子类可按需重写）
## 说明：默认播放名为 "default" 的动画，子类可更改动画名称或使用其他播放方式
func play_animation():
	animation_player.play("default")

## 功能：自动销毁特效节点（子类可按需重写销毁逻辑）
## 说明：默认等待动画播放完成后调用 queue_free() 销毁自身
func auto_destroy():
	await animation_player.finished
	queue_free()

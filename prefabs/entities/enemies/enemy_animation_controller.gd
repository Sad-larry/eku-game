# ==============================================================================
#   EnemyAnimationController.gd
#   功能：敌人动画控制器（当前为占位实现），负责将状态机状态名称映射为具体动画名称
#        并控制 Sprite2D 播放对应动画。待后续根据实际动画资源完善映射逻辑。
# ==============================================================================
extends Node
class_name EnemyAnimationController

# ========================== 节点引用模块 ==========================
## 敌人的 Sprite2D 节点（位于当前节点的父级下，路径为 ../Sprite2D）
@onready var sprite: Sprite2D = $"../Sprite2D"

# ========================== 常量/变量模块 ==========================
## 状态到动画名称的映射表（当前预留，待实际动画资源确定后启用）
# TODO: 根据实际动画资源名称完善映射关系
#var _anim_map: Dictionary = {
#	"idle":     "idle",      # 待机状态
#	"chase":    "move",      # 追击/移动状态
#	"attack":   "attack",    # 攻击状态
#	"hurt":     "hurt",      # 受击硬直状态
#	"dead":     "dead",      # 死亡状态
#	"cooldown": "idle",      # 冷却状态（复用待机动画）
#}

# ========================== 公共 API 模块 ==========================
## 功能：根据状态名称播放对应动画（当前为占位实现）
## 参数：_state_name (String) - 状态机状态名称（如 "idle"、"chase"、"attack" 等）
## 说明：待后续完善时，需将状态名称通过 _anim_map 映射为实际动画名称，
##       并调用 sprite.play(anim_name) 进行播放
func play_state(_state_name: String) -> void:
	# TODO: 实现状态到动画的映射与播放逻辑
	# 示例代码（待动画资源确定后取消注释）：
	# var anim_name: String = _anim_map.get(state_name, "idle")
	# if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
	#     sprite.play(anim_name)
	pass

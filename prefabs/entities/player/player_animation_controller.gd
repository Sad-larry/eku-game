# ==============================================================================
#   player_animation_controller.gd
#   功能：玩家动画控制器，驱动 AnimationPlayer 播放对应动画，
#        将状态+方向映射为具体动画名，并监听动画完成事件。
#        同时负责身体部位的渲染层级管理（z_index 排序），
#        解决多 Sprite 重叠导致的闪烁和遮挡问题。
# ==============================================================================
extends Node
class_name PlayerAnimationController

# ========================== 信号声明模块 ==========================
## 触发时机：动画播放完成时触发
## 参数：state_name (String) - 动画对应的状态名称（如 "dead"、"move"）
signal anim_finished(state_name: String)

# ========================== 节点引用模块 ==========================
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var _arm_right: Sprite2D = $"../Visual/BodyParts/ArmRight"
@onready var _arm_left: Sprite2D = $"../Visual/BodyParts/ArmLeft"

# ========================== 常量定义模块 ==========================
## 不需要方向后缀的状态列表（如死亡、受击只有一个通用动画）
const DIRECTIONLESS_STATES: Array[String] = ["dead", "hurt", "recovery"]

## 身体部位 z_index 层级（按渲染从底到顶排列）
## Legs=0, Body=2, ArmRight(右)=1, Head=4, ArmLeft=3
const Z_ARM_BEHIND: int = 1  # Arm 在 Body(2) 之下
const Z_ARM_FRONT: int = 3  # Arm 在 Body(2) 之上

# ========================== 内部状态模块 ==========================
## 上一次水平朝向符号，避免每帧重复设置 z_index
var _last_horizon_sign: float = 0.0

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	anim_player.animation_finished.connect(_on_anim_finished)

# ========================== 公共 API 模块 ==========================
## 功能：播放指定状态的动画
## 参数：state (String) - 状态名称（如 "idle"、"move"、"dead"）
## 参数：direction (Vector2) - 面朝方向，仅对需要方向的状态有效
## 说明：对于 dead、hurt 等在 DIRECTIONLESS_STATES 中的状态，不附加方向后缀。
##       如果目标动画已在播放中，不会重复触发，避免破坏循环。
func play_anim(state: String, direction: Vector2) -> void:
	var anim_name := state
	if state not in DIRECTIONLESS_STATES:
		anim_name += "_" + DirectionUtils.vector_to_dir_name(direction)
	if anim_player.has_animation(anim_name):
		# 已在播放相同动画时跳过，防止反复 restart 破坏循环
		if anim_player.current_animation == anim_name and anim_player.is_playing():
			return
		anim_player.play(anim_name)

## 功能：播放技能动画
## 参数：skill_anim_base (String) - 技能动画基础名称（如 "fireball"）
## 参数：direction (Vector2) - 面朝方向
## 说明：动画名拼装为 skill_{base_name}_{direction}，如 "skill_fireball_down"
func play_skill(skill_anim_base: String, direction: Vector2) -> void:
	var dir_name := DirectionUtils.vector_to_dir_name(direction)
	var anim_name := "skill_%s_%s" % [skill_anim_base, dir_name]
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

## 功能：设置当前移动方向（外部统一接口）
## 参数：_dir (Vector2) - 当前移动方向
func set_movement_direction(_dir: Vector2) -> void:
	pass

## 功能：根据面朝方向动态调整 ArmBack 的 z_index，解决手臂遮挡问题。
## 说明：当角色面向左方时 ArmBack 置于 Body 之下（z=1），
##       面向右方或垂直方向时置于 Body 之上（z=3）。
##       配合场景中预设的各部位 z_index 层级间隔，也消除了多 Sprite
##       重叠导致的渲染闪烁。
## 参数：direction (Vector2) - 当前面朝方向
func update_arm_sorting(direction: Vector2) -> void:
	var horizon := direction.x
	if sign(horizon) == _last_horizon_sign:
		return
	_last_horizon_sign = sign(horizon)

	_arm_right.z_index = Z_ARM_BEHIND if horizon < 0.0 else Z_ARM_FRONT
	_arm_left.z_index = Z_ARM_FRONT if horizon < 0.0 else Z_ARM_BEHIND


# ========================== 信号回调模块 ==========================
## 功能：AnimationPlayer 动画完成时的回调，解析完整动画名提取状态名
## 参数：anim_name (StringName) - 完成的完整动画名（如 "move_down"、"dead"）
## 说明：通过前缀匹配从完整动画名中提取状态名，再通过 anim_finished 信号转发。
##       例如 "move_down" 匹配 "move_" 前缀 → 发射 "move"；
##       "dead" 匹配 "dead" 前缀 → 发射 "dead"。
func _on_anim_finished(anim_name: StringName) -> void:
	var name_str := String(anim_name)
	for prefix in DIRECTIONLESS_STATES + ["idle_", "move_", "attack_", "skill_"]:
		if name_str.begins_with(prefix):
			anim_finished.emit(prefix.trim_suffix("_"))
			return

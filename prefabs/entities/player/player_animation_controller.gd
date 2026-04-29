# ==============================================================================
#   PlayerAnimationController.gd
#   功能：玩家动画控制器，负责根据移动方向映射8方向动画名称、控制动画状态机
#        播放（待机/移动/攻击/受击/死亡/技能），并监听动画完成事件。
# ==============================================================================
extends Node
class_name PlayerAnimationController

# ========================== 信号声明模块 ==========================
## 触发时机：动画播放完成时触发（用于状态机感知动画结束）
## 参数：state_name (String) - 动画对应的状态名称（如 "dead"、"attack"）
signal animation_finished(state_name: String)

# ========================== 节点引用模块 ==========================
## 动画树节点（需在场景中通过 %AnimationTree 唯一命名）
@onready var anim_tree: AnimationTree = %AnimationTree

## 动画状态机播放控制器（用于切换动画状态）
var playback

# ========================== 常量定义模块 ==========================
## 8方向向量到方向名称的映射表
const DIRECTION_NAMES := {
	Vector2(0, 1):    "down",        # 向下
	Vector2(-1, 1):   "down_left",   # 左下
	Vector2(-1, 0):   "left",        # 向左
	Vector2(-1, -1):  "up_left",     # 左上
	Vector2(0, -1):   "up",          # 向上
	Vector2(1, -1):   "up_right",    # 右上
	Vector2(1, 0):    "right",       # 向右
	Vector2(1, 1):    "down_right",  # 右下
}

## 所有方向向量列表（用于最近邻匹配）
var direction_vectors := DIRECTION_NAMES.keys()

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时获取动画播放控制器并连接动画完成信号
func _ready() -> void:
	playback = anim_tree.get("parameters/MoveStateMachine/playback")
	anim_tree.animation_finished.connect(_on_anim_finished)

# ========================== 辅助方法模块 ==========================
## 功能：将方向向量转换为对应的方向名称（通过点积最近邻匹配）
## 参数：dir (Vector2) - 目标方向向量（建议归一化）
## 返回值：String - 方向名称（如 "up"、"down_right"）
func _vector_to_dir_name(dir: Vector2) -> String:
	var nearest = direction_vectors[0]
	var best_dot = -INF
	for v in direction_vectors:
		var d = dir.dot(v)
		if d > best_dot:
			best_dot = d
			nearest = v
	return DIRECTION_NAMES[nearest]

# ========================== 公共 API 模块 ==========================
## 功能：播放技能动画（技能数据驱动，根据技能攻击名称和面朝方向拼接完整动画名）
## 参数：anim_base_name (String) - 技能动画基础名称（如 "slash"）；direction (Vector2) - 面朝方向
func play_skill_animation(anim_base_name: String, direction: Vector2) -> void:
	var dir_name = _vector_to_dir_name(direction)
	var full_anim_name = "skill_%s_%s" % [anim_base_name, dir_name]
	var anim_path = "parameters/MoveStateMachine/skill/anim_selector/animation"
	anim_tree.set(anim_path, full_anim_name)
	playback.travel("skill")

## 功能：设置移动方向（影响待机/移动/攻击/受击/死亡动画的混合方向参数）
## 参数：dir (Vector2) - 当前移动方向（单位向量）
func set_movement_direction(dir: Vector2) -> void:
	anim_tree.set("parameters/MoveStateMachine/idle/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/move/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/attack/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/hurt/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/dead/blend_position", dir)

## 功能：播放指定状态的动画（通过动画状态机切换）
## 参数：state (String) - 状态名称（如 "idle"、"move"、"attack"）
func play_state(state: String) -> void:
	playback.travel(state)

# ========================== 信号回调模块 ==========================
## 功能：动画完成时的回调（解析动画名称并发射 animation_finished 信号）
## 参数：anim_name (StringName) - 完成的动画名称
## 命名约定：各状态的动画文件命名格式为 "<state>_<direction>"
## 示例：dead_down、dead_up、idle_down、move_right、attack_left、hurt_up、skill_slash_down
func _on_anim_finished(anim_name: StringName) -> void:
	var name_str = String(anim_name)
	# 遍历前缀匹配，提取状态名称
	for prefix in ["dead", "idle_", "move_", "attack_", "hurt_", "skill_"]:
		if name_str.begins_with(prefix):
			# 去掉末尾的下划线，取出状态名（如 "dead"、"idle"）
			animation_finished.emit(prefix.trim_suffix("_"))
			break

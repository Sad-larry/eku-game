extends Node
class_name PlayerAnimationController

signal animation_finished(state_name: String)

@onready var anim_tree: AnimationTree = %AnimationTree
var playback

func _ready() -> void:
	playback = anim_tree.get("parameters/MoveStateMachine/playback")
	anim_tree.animation_finished.connect(_on_anim_finished)
	
# 8 方向名称映射表
const DIRECTION_NAMES := {
	Vector2(0, 1): "down",
	Vector2(-1, 1): "down_left",
	Vector2(-1, 0): "left",
	Vector2(-1, -1): "up_left",
	Vector2(0, -1): "up",
	Vector2(1, -1): "up_right",
	Vector2(1, 0): "right",
	Vector2(1, 1): "down_right",
}

var direction_vectors := DIRECTION_NAMES.keys()

# 将方向向量转为方向名称
func _vector_to_dir_name(dir: Vector2) -> String:
	var nearest = direction_vectors[0]
	var best_dot = -INF
	for v in direction_vectors:
		var d = dir.dot(v)
		if d > best_dot:
			best_dot = d
			nearest = v
	return DIRECTION_NAMES[nearest]

# 播放技能动画（技能数据驱动）
func play_skill_animation(anim_base_name: String, direction: Vector2) -> void:
	var dir_name = _vector_to_dir_name(direction)
	var full_anim_name = "skill_%s_%s" % [anim_base_name, dir_name]
	var anim_path = "parameters/MoveStateMachine/skill/anim_selector/animation"
	anim_tree.set(anim_path, full_anim_name)
	playback.travel("skill")


func set_movement_direction(dir: Vector2) -> void:
	anim_tree.set("parameters/MoveStateMachine/idle/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/move/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/attack/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/hurt/blend_position", dir)
	anim_tree.set("parameters/MoveStateMachine/dead/blend_position", dir)

func play_state(state: String) -> void:
	playback.travel(state)


func _on_anim_finished(anim_name: StringName) -> void:
	var name_str = String(anim_name)
	# 命名约定：各状态的动画文件命名格式为 "<state>_<direction>"
	# 例如 dead_down, dead_up, dead_left ...
	for prefix in ["dead", "idle_", "move_", "attack_", "hurt_", "skill_"]:
		if name_str.begins_with(prefix):
			# 去掉末尾的 "_"，取出状态名 "dead"
			animation_finished.emit(prefix.trim_suffix("_"))
			break

# ==============================================================================
#   direction_utils.gd
#   功能：8方向向量与方向名称之间的映射工具
# ==============================================================================
extends RefCounted
class_name DirectionUtils

## 8方向原始向量列表（未归一化，比较时内部归一化）
const DIRECTION_VECTORS: Array[Vector2] = [
	Vector2(0, 1),     # 下
	Vector2(-1, 1),    # 左下
	Vector2(-1, 0),    # 左
	Vector2(-1, -1),   # 左上
	Vector2(0, -1),    # 上
	Vector2(1, -1),    # 右上
	Vector2(1, 0),     # 右
	Vector2(1, 1),     # 右下
]

## 与上列向量一一对应的方向名称
const DIRECTION_NAMES: Array[String] = [
	"down",
	"down_left",
	"left",
	"up_left",
	"up",
	"up_right",
	"right",
	"down_right",
]

## 功能：将方向向量转换为对应的方向名称（通过点积最近邻匹配）
## 参数：dir (Vector2) - 目标方向向量（无需预先归一化）
## 返回值：String - 方向名称（如 "up"、"down_right"），若为零向量则返回默认值 "down"
static func vector_to_dir_name(dir: Vector2) -> String:
	if dir.length() == 0:
		return "down"
	var normalized_dir := dir.normalized()
	var best_angle := -1.0
	var best_idx := 0
	for i in DIRECTION_VECTORS.size():
		var dot := normalized_dir.dot(DIRECTION_VECTORS[i].normalized())
		if dot > best_angle:
			best_angle = dot
			best_idx = i
	return DIRECTION_NAMES[best_idx]

## 功能：将任意向量映射到 8 个主方向之一的单位向量（8 方向标准化）
## 参数：dir (Vector2) - 原始输入向量（无需预先标准化）
## 返回值：Vector2 - 归一化后的 8 方向单位向量，若输入趋近零向量则返回 Vector2.ZERO
static func normalize_8_direction(dir: Vector2) -> Vector2:
	if dir.length() < 0.01:
		return Vector2.ZERO
	var normalized_dir := dir.normalized()
	var best_angle := -1.0
	var best_vec := DIRECTION_VECTORS[0]
	for v in DIRECTION_VECTORS:
		var dot := normalized_dir.dot(v.normalized())
		if dot > best_angle:
			best_angle = dot
			best_vec = v
	return best_vec.normalized()

## 功能：获取方向向量对应的 8 方向枚举索引
## 参数：dir (Vector2) - 方向向量
## 返回值：int - 方向索引（0~7），若输入为零向量则返回 -1
static func get_eight_direction_enum(dir: Vector2) -> int:
	if dir.length() < 0.01:
		return -1
	var eight_dir := normalize_8_direction(dir)
	for i in DIRECTION_VECTORS.size():
		if eight_dir == DIRECTION_VECTORS[i].normalized():
			return i
	return -1

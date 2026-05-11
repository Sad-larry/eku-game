# ==============================================================================
#   portal_zone.gd
#   功能：传送方块组件，挂载在 Area2D 上，包含两个菱形碰撞体：
#         PortalPrepareCollision — 检测玩家踏入比例，驱动过渡效果
#         PortalActiveCollision  — 玩家踏入则立即触发传送完成
#   场景结构要求：
#     PortalZone (Area2D) — 添加到组 "iso_sort_ignore"
#       ├─ PortalPrepareCollision (CollisionPolygon2D)
#       ├─ PortalActiveCollision (Area2D)
#       │   └─ CollisionPolygon2D (较小的菱形)
#       ├─ Sprite2D
#       └─ Label
# ==============================================================================
extends Area2D
class_name PortalZone

# ========================== 导出变量模块 ==========================
## 本传送方块的唯一标识 ID
@export var portal_id: String = ""

## 目标场景资源路径
@export var target_scene_path: String = ""

## 目标场景中对应传送方块的 portal_id
@export var target_portal_id: String = ""

## 目标场景的名字
@export var target_room_name: String = ""


# ========================== 信号声明模块 ==========================
## 玩家首次踏入传送方块（body_entered 触发）
signal player_entered(body: Node2D)

## 玩家踏入比例更新（每帧），progress 范围 0.0 ~ 1.0
signal player_enter_progress(progress: float, body: Node2D)

## 玩家完全退出传送方块
signal player_exit(body: Node2D)

## 玩家踏入 PortalActiveCollision，触发传送完成
signal portal_activated(body: Node2D)


# ========================== 节点引用模块 ==========================
@onready var prepare_collision: CollisionPolygon2D = $PortalPrepareCollision
@onready var active_area: Area2D = $PortalActiveCollision
@onready var label: Label = $Label


# ========================== 变量定义模块 ==========================
## 传送方块尺寸（从 PortalPrepareCollision 的菱形 AABB 读取）
var portal_size: Vector2:
	get:
		return _cached_size

## 当前正在踏入的玩家引用
var _tracked_body: Node2D = null

## 缓存尺寸
var _cached_size: Vector2 = Vector2.ONE

## 是否已通过 PortalActiveCollision 触发传送
var _active_triggered: bool = false


# ========================== 生命周期模块 ==========================
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	active_area.body_entered.connect(_on_active_body_entered)
	_cached_size = _read_shape_size()
	label.text = target_room_name
	


func _process(_delta: float) -> void:
	# 无跟踪目标时跳过
	if not _tracked_body or not is_instance_valid(_tracked_body):
		return

	# 计算当前踏入比例并发射信号
	var progress := get_entry_progress(_tracked_body.global_position)
	player_enter_progress.emit(progress, _tracked_body)


# ========================== 公共方法模块 ==========================
## 计算玩家脚底位置在菱形传送方块中的踏入比例
func get_entry_progress(body_global_pos: Vector2) -> float:
	var global_poly := _get_global_polygon()
	if global_poly.is_empty():
		return 0.0
	if not Geometry2D.is_point_in_polygon(body_global_pos, global_poly):
		return 0.0

	var uv := _get_diamond_uv(body_global_pos)
	var dist :float = abs(uv.x) + abs(uv.y)
	return clampf(1.0 - dist, 0.0, 1.0)


## 将源方块中的玩家位置映射到目标方块的世界坐标
static func map_position_to_target(
	source: PortalZone,
	target: PortalZone,
	source_pos: Vector2
) -> Vector2:
	var uv := source._get_diamond_uv(source_pos)
	return target._diamond_uv_to_world(uv.x, uv.y)


## 获取玩家相对于菱形质心的方向
func get_entry_direction(body_global_pos: Vector2) -> Vector2:
	var uv := _get_diamond_uv(body_global_pos)
	return Vector2(uv.x, uv.y).normalized()


## 启用/禁用 PortalActiveCollision 的碰撞检测
func set_active_collision_enabled(enabled: bool) -> void:
	active_area.set_deferred("monitoring", enabled)
	active_area.set_deferred("monitorable", enabled)


## 获取 PortalActiveCollision 的全局位置（传送落点）
func get_active_collision_position() -> Vector2:
	return active_area.global_position

## 清除跟踪状态，强制玩家完全退出后再进入才能重新触发。
## 由 LobbyPortalManager 在传送完成后调用。
func reset_tracking() -> void:
	_tracked_body = null
	_active_triggered = false

# ========================== 菱形坐标方法模块 ==========================
## 全局坐标 → 菱形 UV 坐标（中心 0,0；四角 ±1,0 / 0,±1）
func _get_diamond_uv(body_global_pos: Vector2) -> Vector2:
	var rect := _get_global_rect()
	var cx := rect.get_center().x
	var cy := rect.get_center().y
	var half_w := rect.size.x * 0.5
	var half_h := rect.size.y * 0.5

	if half_w == 0.0 or half_h == 0.0:
		return Vector2.ZERO

	return Vector2(
		(body_global_pos.x - cx) / half_w,
		(body_global_pos.y - cy) / half_h
	)


## 菱形 UV 坐标 → 全局世界坐标
func _diamond_uv_to_world(u: float, v: float) -> Vector2:
	var rect := _get_global_rect()
	var cx := rect.get_center().x
	var cy := rect.get_center().y
	var half_w := rect.size.x * 0.5
	var half_h := rect.size.y * 0.5

	var dist :float = abs(u) + abs(v)
	if dist > 1.0:
		u /= dist
		v /= dist

	return Vector2(cx + u * half_w, cy + v * half_h)


# ========================== 内部方法模块 ==========================
## 从 PortalPrepareCollision 的菱形顶点计算包围盒尺寸
func _read_shape_size() -> Vector2:
	if not prepare_collision or prepare_collision.polygon.is_empty():
		return Vector2(32.0, 16.0)
	var bounds := Rect2()
	for point in prepare_collision.polygon:
		bounds = bounds.expand(point)
	return bounds.size * global_scale


## 获取菱形多边形在全局坐标下的轴对齐包围矩形
func _get_global_rect() -> Rect2:
	var global_poly := _get_global_polygon()
	if global_poly.is_empty():
		return Rect2(global_position - portal_size * 0.5, portal_size)
	var bounds := Rect2(global_poly[0], Vector2.ZERO)
	for point in global_poly:
		bounds = bounds.expand(point)
	return bounds


## 将 PortalPrepareCollision 多边形顶点从本地坐标变换到全局坐标
func _get_global_polygon() -> PackedVector2Array:
	if not prepare_collision or prepare_collision.polygon.is_empty():
		return PackedVector2Array()
	var result := PackedVector2Array()
	var xform := prepare_collision.global_transform
	for point in prepare_collision.polygon:
		result.append(xform * point)
	return result


# ========================== 信号回调模块 ==========================
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_tracked_body = body
		player_entered.emit(body)


func _on_body_exited(body: Node2D) -> void:
	if body == _tracked_body:
		_tracked_body = null
		_active_triggered = false
		player_exit.emit(body)


func _on_active_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if _active_triggered:
		return
	_active_triggered = true
	portal_activated.emit(body)

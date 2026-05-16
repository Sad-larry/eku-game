# ==============================================================================
#   room_boundary.gd
#   功能：区块空气墙边界。在菱形区块的四个边上生成碰撞 + 视觉屏障，
#         进入战斗房间时封锁，清场后自动消失。
#   用法：由 GameWorld 在检测到玩家进入战斗区块时实例化，
#         调用 setup() 定位，lock() 显示，unlock() 销毁。
# ==============================================================================
extends Node2D
class_name RoomBoundary

## 此边界对应的区块坐标（用于查找匹配）
var chunk_coord: Vector2i

## 区块尺寸（瓦片数），从 ChunkManager 同步
var _chunk_size: int = 48

## 四条边的节点数组
var _edges: Array[Node2D] = []

# ========================== 公共 API ==========================
## 定位边界到指定区块
func setup(cx: int, cy: int, chunk_manager: ChunkManager) -> void:
	chunk_coord = Vector2i(cx, cy)
	_chunk_size = chunk_manager.chunk_size
	var ref := chunk_manager.get_ref_layer()
	var S := _chunk_size
	visible = false  # 初始不可见，由 lock() 启用

	# 计算菱形四个顶点（等距坐标转世界像素）
	var top := ref.map_to_local(Vector2i(cx * S, cy * S))
	var right := ref.map_to_local(Vector2i((cx + 1) * S, cy * S))
	var bottom := ref.map_to_local(Vector2i((cx + 1) * S, (cy + 1) * S))
	var left := ref.map_to_local(Vector2i(cx * S, (cy + 1) * S))

	# 生成四条边
	_create_edge(0, top, right)
	_create_edge(1, right, bottom)
	_create_edge(2, bottom, left)
	_create_edge(3, left, top)

## 封锁：显示空气墙并启用碰撞
func lock() -> void:
	visible = true
	for edge in _edges:
		_apply_collision(edge, true)

## 解锁：淡出并销毁
func unlock() -> void:
	for edge in _edges:
		_apply_collision(edge, false)
	# 简单淡出动画
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	await tween.finished
	queue_free()

# ========================== 内部方法 ==========================
func _create_edge(index: int, from: Vector2, to: Vector2) -> void:
	var mid := (from + to) * 0.5
	var length := from.distance_to(to)
	var angle := from.angle_to_point(to)
	var thickness := 12.0

	# 边容器
	var edge := Node2D.new()
	edge.name = "Edge%d" % index
	edge.position = mid
	edge.rotation = angle
	add_child(edge)
	_edges.append(edge)

	# 碰撞体
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(length + thickness, thickness)
	body.add_child(shape)
	body.collision_layer = 0  # 默认禁用，由 lock() 启用
	body.collision_mask = 0
	edge.add_child(body)

	# 视觉效果（半透明红色屏障）
	var visual := Polygon2D.new()
	var hw := thickness * 0.5
	var half_len := length * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half_len, -hw),
		Vector2( half_len, -hw),
		Vector2( half_len,  hw),
		Vector2(-half_len,  hw),
	])
	visual.color = Color(1.0, 0.2, 0.2, 0.35)
	edge.add_child(visual)

func _apply_collision(edge: Node2D, enabled: bool) -> void:
	for child in edge.get_children():
		if child is StaticBody2D:
			child.set_collision_layer_value(7, enabled)

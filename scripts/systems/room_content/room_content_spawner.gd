# ==============================================================================
#   room_content_spawner.gd
#   功能：房间内容生成器基类。每种事件类型对应一个子类，
#        负责该类型房间的内容生成和清理逻辑。
# ==============================================================================
class_name RoomContentSpawner extends RefCounted

## 功能：生成房间内容
## 参数：coord - 房间坐标，ring - 环数，context - 上下文数据（含 GameWorld 引用等）
func spawn(_coord: Vector2i, _ring: int, _context: Dictionary) -> void:
	push_warning("RoomContentSpawner.spawn() 未实现")

## 功能：判断该房间是否可以生成内容（如已清除则跳过）
## 返回值：true 表示可以生成
func can_spawn(_coord: Vector2i, _ring: int) -> bool:
	return true

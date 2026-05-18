# ==============================================================================
#   room_content_registry.gd
#   功能：房间内容 Spawner 注册表。维护事件类型到 Spawner 的映射。
# ==============================================================================
class_name RoomContentRegistry extends RefCounted

var _spawners: Dictionary = {}  # event_type String -> RoomContentSpawner

## 功能：注册一个事件类型的 Spawner
func register(event_type: String, spawner: RoomContentSpawner) -> void:
	_spawners[event_type] = spawner

## 功能：获取指定事件类型的 Spawner
## 返回值：RoomContentSpawner 或 null
func get_spawner(event_type: String) -> RoomContentSpawner:
	return _spawners.get(event_type)

## 功能：检查是否注册了指定事件类型
func has_spawner(event_type: String) -> bool:
	return _spawners.has(event_type)

## 功能：获取所有已注册的事件类型
func get_registered_types() -> Array[String]:
	var types: Array[String] = []
	for key in _spawners:
		types.append(key)
	return types

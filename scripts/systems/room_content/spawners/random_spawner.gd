# ==============================================================================
#   random_spawner.gd
#   功能：随机事件 Spawner。从子事件列表中随机选择一个并委托执行。
# ==============================================================================
class_name RandomSpawner extends RoomContentSpawner

## 随机事件候选列表
var _sub_events: Array[String] = ["battle"]

## 注册表引用（用于递归查找子事件的 Spawner）
var registry: RoomContentRegistry

func spawn(coord: Vector2i, ring: int, context: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	var chosen: String = _sub_events[rng.randi() % _sub_events.size()]

	# 委托给对应的 Spawner
	if registry and registry.has_spawner(chosen):
		registry.get_spawner(chosen).spawn(coord, ring, context)
	else:
		# 回退：直接调用 GameWorld 的事件分发
		var world: GameWorld = context.get("world")
		if world:
			world._on_room_entered(coord, ring, chosen)

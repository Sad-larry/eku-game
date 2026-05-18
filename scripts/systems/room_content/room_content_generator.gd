# ==============================================================================
#   room_content_generator.gd
#   功能：房间内容生成统一入口。管理注册表，接收房间进入事件，
#        路由到对应的 Spawner 执行内容生成。
# ==============================================================================
class_name RoomContentGenerator extends RefCounted

var _registry: RoomContentRegistry
var _world: GameWorld

## 功能：初始化生成器，注册所有事件类型的 Spawner
## 参数：world - GameWorld 引用
func setup(world: GameWorld) -> void:
	_world = world
	_registry = RoomContentRegistry.new()
	_register_default_spawners()

## 功能：处理房间进入事件，路由到对应的 Spawner
## 参数：coord - 房间坐标，ring - 环数，event_type - 事件类型
func generate_room(coord: Vector2i, ring: int, event_type: String) -> void:
	var spawner := _registry.get_spawner(event_type)
	if spawner == null:
		push_warning("RoomContentGenerator: 未注册的事件类型 '%s'" % event_type)
		return

	var context := {"world": _world}
	spawner.spawn(coord, ring, context)

	EventBus.room_content_generated.emit(coord, event_type)

## 功能：注册默认 Spawners
func _register_default_spawners() -> void:
	_registry.register("battle", BattleSpawner.new())
	_registry.register("elite", EliteSpawner.new())
	_registry.register("boss", BossSpawner.new())
	_registry.register("start", StartSpawner.new())
	_registry.register("treasure", TreasureSpawner.new())
	_registry.register("rest", RestSpawner.new())
	_registry.register("trap", TrapSpawner.new())
	_registry.register("merchant", MerchantSpawner.new())
	_registry.register("npc", NpcSpawner.new())
	_registry.register("hidden", HiddenSpawner.new())
	_registry.register("teleport", TeleportSpawner.new())

	var random_spawner := RandomSpawner.new()
	random_spawner.registry = _registry
	_registry.register("random", random_spawner)

## 功能：注册自定义 Spawner（供外部扩展）
func register_spawner(event_type: String, spawner: RoomContentSpawner) -> void:
	_registry.register(event_type, spawner)

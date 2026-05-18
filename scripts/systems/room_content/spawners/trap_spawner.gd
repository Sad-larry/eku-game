# ==============================================================================
#   trap_spawner.gd
#   功能：陷阱房间 Spawner。在房间内随机位置生成多个陷阱。
# ==============================================================================
class_name TrapSpawner extends RoomContentSpawner

const _TRAP_SCENES: Array[PackedScene] = [
	preload("res://prefabs/environment/traps/trap_spike.tscn"),
	preload("res://prefabs/environment/traps/trap_poison.tscn"),
	preload("res://prefabs/environment/traps/trap_slow.tscn"),
	preload("res://prefabs/environment/traps/trap_stun.tscn"),
]

func spawn(coord: Vector2i, ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	var room_center := world._chunk_to_world_center(coord.x, coord.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord) + 7  # 偏移种子避免与其他生成冲突

	# 根据 ring 生成 2~4 个陷阱
	var trap_count: int = mini(2 + ring, 4)
	for i in trap_count:
		var scene: PackedScene = _TRAP_SCENES[rng.randi() % _TRAP_SCENES.size()]
		var trap: TrapBase = scene.instantiate()
		trap.setup(ring)
		trap.position = room_center + Vector2(
			rng.randf_range(-120.0, 120.0),
			rng.randf_range(-120.0, 120.0)
		)
		world.add_child(trap)

	# 陷阱房间清除逻辑：进入即清除（陷阱已生成）
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

	if Global.DEBUG_MODE:
		print("[GameWorld] 陷阱房间: 生成 ", trap_count, " 个陷阱于 ", coord)

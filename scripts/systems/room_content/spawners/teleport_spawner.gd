# ==============================================================================
#   teleport_spawner.gd
#   功能：传送门房间 Spawner。占位实现，待后续扩展。
# ==============================================================================
class_name TeleportSpawner extends RoomContentSpawner

func spawn(coord: Vector2i, _ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	if Global.DEBUG_MODE:
		print("[GameWorld] 传送门（占位）: ", coord)

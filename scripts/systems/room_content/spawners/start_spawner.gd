# ==============================================================================
#   start_spawner.gd
#   功能：起始房间 Spawner。生成安全区标记。
# ==============================================================================
class_name StartSpawner extends RoomContentSpawner

func spawn(coord: Vector2i, _ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	var safe_zone := Global.SAFE_ZONE_SCENE.instantiate() as SafeZoneMarker
	safe_zone.position = world._chunk_to_world_center(coord.x, coord.y)
	world.add_child(safe_zone)

	if Global.DEBUG_MODE:
		print("[GameWorld] 安全区已生成于: ", coord)

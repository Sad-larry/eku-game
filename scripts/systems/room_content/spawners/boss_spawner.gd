# ==============================================================================
#   boss_spawner.gd
#   功能：Boss 房间 Spawner。生成 Boss 实体和层间传送门。
# ==============================================================================
class_name BossSpawner extends RoomContentSpawner

func spawn(coord: Vector2i, ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if RoomManager.is_cleared(coord):
		return

	world._ensure_boundary(coord)

	if not world._spawned_rooms.has(coord):
		var boss_config := world._get_boss_config_for_layer()
		if boss_config and boss_config.boss_scene:
			world._spawn_boss(coord, boss_config)
		elif world.battle_config:
			world._spawn_enemies_for_room(coord, "boss")
		world._spawned_rooms[coord] = true

func can_spawn(coord: Vector2i, _ring: int) -> bool:
	return not RoomManager.is_cleared(coord)

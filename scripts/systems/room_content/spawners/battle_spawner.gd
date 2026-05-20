# ==============================================================================
#   battle_spawner.gd
#   功能：战斗房间 Spawner。生成敌人并追踪清场状态。
# ==============================================================================
class_name BattleSpawner extends RoomContentSpawner

func spawn(coord: Vector2i, _ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if RoomManager.is_cleared(coord):
		return

	world._ensure_boundary(coord)

	if not world._spawned_rooms.has(coord) and world.battle_config != null:
		world._spawn_enemies_for_room(coord, "battle")
		world._spawned_rooms[coord] = true

func can_spawn(coord: Vector2i, _ring: int) -> bool:
	return not RoomManager.is_cleared(coord)

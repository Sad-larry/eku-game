# ==============================================================================
#   npc_spawner.gd
#   功能：NPC 事件房间 Spawner。在房间中心生成事件 NPC。
# ==============================================================================
class_name NpcSpawner extends RoomContentSpawner

const _NPC_SCENE: PackedScene = preload("res://prefabs/entities/npcs/event_npc.tscn")

func spawn(coord: Vector2i, _ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	var npc: EventNPC = _NPC_SCENE.instantiate()
	npc.position = world._chunk_to_world_center(coord.x, coord.y)
	world.add_child(npc)

	if Global.DEBUG_MODE:
		print("[GameWorld] 事件 NPC 已生成于: ", coord)

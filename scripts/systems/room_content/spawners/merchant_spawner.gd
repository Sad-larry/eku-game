# ==============================================================================
#   merchant_spawner.gd
#   功能：商人房间 Spawner。在房间中心生成商人 NPC。
# ==============================================================================
class_name MerchantSpawner extends RoomContentSpawner

const _MERCHANT_SCENE: PackedScene = preload("res://prefabs/entities/npcs/merchant_npc.tscn")

func spawn(coord: Vector2i, ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	var npc: MerchantNPC = _MERCHANT_SCENE.instantiate()
	npc.ring = ring
	npc.position = world._chunk_to_world_center(coord.x, coord.y)
	world.add_child(npc)

	if Global.DEBUG_MODE:
		print("[GameWorld] 商人 NPC 已生成于: ", coord)

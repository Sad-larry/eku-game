# ==============================================================================
#   treasure_spawner.gd
#   功能：宝箱房间 Spawner。在房间中心生成一个宝箱实体。
# ==============================================================================
class_name TreasureSpawner extends RoomContentSpawner

const _CHEST_SCENE: PackedScene = preload("res://prefabs/objects/chest/treasure_chest.tscn")

func spawn(coord: Vector2i, ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	var chest: TreasureChest = _CHEST_SCENE.instantiate()
	chest.position = world._chunk_to_world_center(coord.x, coord.y)
	chest.rarity = TreasureChest.roll_rarity(ring)
	world.add_child(chest)

	if Global.DEBUG_MODE:
		print("[GameWorld] 宝箱已生成于: ", coord, " 稀有度: ", chest.rarity)

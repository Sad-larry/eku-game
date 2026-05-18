# ==============================================================================
#   hidden_spawner.gd
#   功能：隐藏房间 Spawner。在房间入口放置可破坏隐藏墙。
# ==============================================================================
class_name HiddenSpawner extends RoomContentSpawner

const _WALL_SCENE: PackedScene = preload("res://prefabs/environment/hidden_wall/hidden_wall.tscn")

func spawn(coord: Vector2i, ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	# 在房间边缘放置隐藏墙
	var room_center := world._chunk_to_world_center(coord.x, coord.y)
	var wall: HiddenWall = _WALL_SCENE.instantiate()
	wall.position = room_center + Vector2(0, -80)  # 房间上方
	world.add_child(wall)

	# 隐藏房间内的额外奖励（打破墙后才暴露）
	var bonus_coins: int = (ring + 1) * 20
	CurrencyManager.add_coin(bonus_coins)

	if Global.DEBUG_MODE:
		print("[GameWorld] 隐藏墙已生成于: ", coord)

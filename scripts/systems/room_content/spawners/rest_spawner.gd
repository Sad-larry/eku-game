# ==============================================================================
#   rest_spawner.gd
#   功能：休息房间 Spawner。在房间中心生成一个休息点实体。
# ==============================================================================
class_name RestSpawner extends RoomContentSpawner

const _REST_SCENE: PackedScene = preload("res://prefabs/objects/rest_point/rest_point.tscn")

func spawn(coord: Vector2i, _ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if world._spawned_rooms.has(coord):
		return
	world._spawned_rooms[coord] = true

	var rest_point: RestPoint = _REST_SCENE.instantiate()
	rest_point.position = world._chunk_to_world_center(coord.x, coord.y)
	world.add_child(rest_point)

	if Global.DEBUG_MODE:
		print("[GameWorld] 休息点已生成于: ", coord)

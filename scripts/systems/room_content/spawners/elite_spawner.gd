# ==============================================================================
#   elite_spawner.gd
#   功能：精英房间 Spawner。生成带精英修饰符的敌人。
# ==============================================================================
class_name EliteSpawner extends RoomContentSpawner

const _ELITE_SCENE: PackedScene = preload("res://prefabs/entities/enemies/elite/enemy_elite.tscn")

func spawn(coord: Vector2i, _ring: int, context: Dictionary) -> void:
	var world: GameWorld = context.get("world")
	if world == null:
		return

	if RoomManager.is_cleared(coord):
		return

	world._ensure_boundary(coord)

	if not world._spawned_rooms.has(coord):
		var room_center := world._chunk_to_world_center(coord.x, coord.y)

		# 生成精英敌人
		var elite: EnemyElite = _ELITE_SCENE.instantiate()
		elite.global_position = room_center + Vector2(randf_range(-50, 50), randf_range(-30, 30))
		world.enemy_container.add_child(elite)

		# 同时生成 2 个普通敌人作为护卫
		if world.battle_config and not world.battle_config.enemy_entries.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(coord) + 42
			for i in 2:
				var entry = world.battle_config.enemy_entries[rng.randi() % world.battle_config.enemy_entries.size()]
				if entry.enemy_scene:
					var guard: Enemy = entry.enemy_scene.instantiate()
					guard.global_position = room_center + Vector2(randf_range(-80, 80), randf_range(-50, 50))
					world.enemy_container.add_child(guard)

		# 创建清场追踪器
		var tracker := RoomEnemyTracker.new()
		tracker.name = "EliteTracker_%d_%d" % [coord.x, coord.y]
		world.enemy_container.add_child(tracker)
		var enemies: Array[Enemy] = [elite]
		tracker.setup(coord, enemies)
		tracker.all_enemies_defeated.connect(func() -> void:
			RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
		)
		world._room_trackers[coord] = tracker
		world._spawned_rooms[coord] = true

		if Global.DEBUG_MODE:
			print("[GameWorld] 精英敌人已生成于: ", coord)

func can_spawn(coord: Vector2i, _ring: int) -> bool:
	return not RoomManager.is_cleared(coord)

extends Node2D
class_name RoomBase

# ========================== 导出变量 ==========================
@export var room_data: RoomResource              # 房间配置（包含敌人波次、奖励等）
@export var spawn_points: Array[Node2D]          # 敌人生成点列表
@export var exit_door: Node2D                    # 出口门节点（初始关闭）

# 房间配置（可通过资源文件扩展）
@export var room_id: String = "empty_room_01"  # 房间唯一标识
@export var is_battle_room: bool = false  # 是否为战斗房间（预留）
# 节点引用
@onready var collision_container = $Collision

# ========================== 内部状态 ==========================
enum RoomState { INACTIVE, ACTIVATING, ACTIVE, CLEARING, COMPLETED }
var state: RoomState = RoomState.INACTIVE

# 生成的敌人实例列表
var _enemies: Array[Node] = []
# 当前波次索引
var _current_wave: int = 0

# ========================== 信号 ==========================
signal room_activated(room: RoomBase)
signal room_cleared(room: RoomBase)
signal enemy_spawned(enemy: Node)
signal enemy_died(enemy: Node)

# 初始化
func _ready() -> void:
	# 初始关闭出口门（假设门有 close() 方法或不可见）
	if exit_door:
		exit_door.visible = false
		if exit_door.has_method("close"):
			exit_door.close()
	RoomManager.register_room(self)
	GameManager.game_state_changed.connect(_on_game_state_changed)

func _exit_tree() -> void:
	GameManager.game_state_changed.disconnect(_on_game_state_changed)

# 游戏状态变化回调
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.IN_GAME:
			collision_container.set_process(true)
		GameManager.GameState.PAUSED:
			collision_container.set_process(false)
		_:
			pass

# 房间激活（进入房间时调用）
func activate_room() -> void:
	visible = true
	collision_container.set_physics_process(true)
	# 可扩展：生成敌人、播放房间激活音效等
	RoomManager.set_current_room(room_id)
	
	if state != RoomState.INACTIVE:
		return
	state = RoomState.ACTIVATING
	print("[Room] 激活房间: ", name)
	
	# 如果有 room_data，按波次生成；否则从生成点生成默认敌人
	if room_data and room_data.waves.size() > 0:
		_start_wave(_current_wave)
	else:
		_spawn_enemies_from_points()
	
	state = RoomState.ACTIVE
	room_activated.emit(self)

# 房间休眠（离开房间时调用）
func deactivate_room() -> void:
	visible = false
	collision_container.set_physics_process(false)
	# 可扩展：清理敌人、停止房间音效等
	if state == RoomState.INACTIVE:
		return
	print("[Room] 休眠房间: ", name)
	_clear_enemies()
	_clear_drops()
	state = RoomState.INACTIVE

func _on_end_body_entered(_body: Node2D) -> void:
	UIManager.open_game_over()


## 检查房间是否已完成（所有波次敌人都清理完毕）
func is_completed() -> bool:
	return state == RoomState.COMPLETED

# ========================== 内部方法 ==========================
## 根据生成点直接生成敌人（无波次配置时使用）
func _spawn_enemies_from_points() -> void:
	for spawn in spawn_points:
		if not spawn:
			continue
		# 假设敌人场景路径存储在 room_data.enemy_scene；若没有，使用一个默认敌人
		var enemy_scene = room_data.default_enemy_scene if room_data else null
		if not enemy_scene:
			push_error("房间 %s 缺少敌人场景配置" % name)
			return
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn.global_position
		add_child(enemy)
		_enemies.append(enemy)
		_connect_enemy_signals(enemy)
		enemy_spawned.emit(enemy)

## 开始指定波次（支持多波次）
func _start_wave(wave_index: int) -> void:
	var wave = room_data.waves[wave_index]
	for unit_data in wave.units:
		var enemy_scene = unit_data.unit_scene
		var enemy = enemy_scene.instantiate()
		enemy.global_position = global_position + Vector2(randf_range(-100,100), randf_range(-100,100))
		add_child(enemy)
		_enemies.append(enemy)
		_connect_enemy_signals(enemy)
		enemy_spawned.emit(enemy)
	# 如果波次有延迟生成逻辑，可在这里添加 Timer

## 清理所有敌人
func _clear_enemies() -> void:
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()

## 清理掉落物（假设掉落物有特定分组或标记）
func _clear_drops() -> void:
	# 方法1：通过组清理
	var drops = get_tree().get_nodes_in_group("room_drops")
	for drop in drops:
		if drop and is_instance_valid(drop):
			drop.queue_free()
	# 方法2：遍历子节点中特定类型（如 DropItem）
	for child in get_children():
		if child.is_in_group("drop") or child.has_method("collect"):
			child.queue_free()

## 连接敌人的死亡信号
func _connect_enemy_signals(enemy: Node) -> void:
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))
	elif enemy.has_signal("health_depleted"):
		enemy.health_depleted.connect(_on_enemy_died.bind(enemy))
	else:
		# 如果敌人没有死亡信号，可以尝试获取其 HealthComponent
		var health = enemy.get_node_or_null("HealthComponent")
		if health and health.has_signal("unit_died"):
			health.unit_died.connect(_on_enemy_died.bind(enemy))

## 敌人死亡回调
func _on_enemy_died(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	# 从 _enemies 列表中移除
	var idx = _enemies.find(enemy)
	if idx != -1:
		_enemies.remove_at(idx)
	enemy_died.emit(enemy)
	
	# 检查是否所有敌人都死亡
	_check_room_cleared()

## 检查房间是否已清理完毕（支持多波次）
func _check_room_cleared() -> void:
	if _enemies.is_empty():
		# 当前波次结束
		if room_data and _current_wave + 1 < room_data.waves.size():
			# 还有下一波
			_current_wave += 1
			_start_wave(_current_wave)
		else:
			# 所有波次完成
			_complete_room()

## 房间完全清理：开放出口、发射信号
func _complete_room() -> void:
	if state == RoomState.COMPLETED:
		return
	state = RoomState.COMPLETED
	print("[Room] 房间清理完成: ", name)
	
	# 开放出口门
	if exit_door:
		exit_door.visible = true
		if exit_door.has_method("open"):
			exit_door.open()
		else:
			# 简单隐藏阻挡碰撞体
			var collision = exit_door.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = true
	room_cleared.emit(self)
	
	# 可选：发射全局事件
	EventBus.room_completed.emit(self)

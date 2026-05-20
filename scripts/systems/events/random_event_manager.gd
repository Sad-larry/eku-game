# ==============================================================================
#   random_event_manager.gd
#   功能：随机事件管理器，管理随机事件的加载、选择和触发。
#        由 RoomContentGenerator 查询，在房间生成时注入随机事件。
# ==============================================================================
extends Node
class_name RandomEventManager

# ========================== 常量 ==========================
## 随机事件资源目录
const EVENTS_DIR: String = "res://resources/data/events/random_events/"

# ========================== 信号 ==========================
## 随机事件触发时发射
signal random_event_triggered(event_id: String, coord: Vector2i)

# ========================== 运行时状态 ==========================
## 已加载的随机事件
var _events: Array[RandomEvent] = []

## 本次运行触发次数 {event_id: count}
var _trigger_counts: Dictionary = {}

## 事件冷却计数器 {event_id: remaining_rooms}
var _cooldowns: Dictionary = {}

# ========================== 生命周期 ==========================
func _ready() -> void:
	_load_events()
	print("[RandomEventManager] 加载了 ", _events.size(), " 个随机事件")

# ========================== 公共 API ==========================
## 功能：为指定房间选择一个随机事件
## 参数：ring (int) - 当前 ring 值；room_tags (Array) - 房间 tags
## 返回值：RandomEvent - 选中的事件，无可用事件返回 null
func select_event(ring: int, room_tags: Array = []) -> RandomEvent:
	var available: Array[RandomEvent] = _get_available_events(ring, room_tags)
	if available.is_empty():
		return null

	# 基于权重随机选择
	return _weighted_random_select(available)

## 功能：记录事件触发
## 参数：event_id (String) - 事件 ID；coord (Vector2i) - 房间坐标
func record_trigger(event_id: String, coord: Vector2i) -> void:
	_trigger_counts[event_id] = _trigger_counts.get(event_id, 0) + 1

	# 设置冷却
	var event := _get_event_by_id(event_id)
	if event and event.cooldown_rooms > 0:
		_cooldowns[event_id] = event.cooldown_rooms

	random_event_triggered.emit(event_id, coord)
	EventBus.random_event_triggered.emit(event_id, coord)

## 功能：房间被访问后减少冷却计数器
func on_room_visited() -> void:
	var expired: Array = []
	for event_id in _cooldowns:
		_cooldowns[event_id] -= 1
		if _cooldowns[event_id] <= 0:
			expired.append(event_id)
	for event_id in expired:
		_cooldowns.erase(event_id)

## 功能：重置运行时状态
func reset_run_state() -> void:
	_trigger_counts.clear()
	_cooldowns.clear()

## 功能：获取所有已加载的随机事件
func get_all_events() -> Array[RandomEvent]:
	return _events

# ========================== 内部方法 ==========================
func _load_events() -> void:
	var dir := DirAccess.open(EVENTS_DIR)
	if dir == null:
		# 目录不存在时静默跳过
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(EVENTS_DIR + file_name)
			if resource is RandomEvent:
				_events.append(resource)
		file_name = dir.get_next()

func _get_available_events(ring: int, room_tags: Array) -> Array[RandomEvent]:
	var result: Array[RandomEvent] = []

	for event in _events:
		# 检查 ring 范围
		if ring < event.min_ring or ring > event.max_ring:
			continue

		# 检查触发次数限制
		if event.max_triggers_per_run > 0:
			var count: int = _trigger_counts.get(event.id, 0)
			if count >= event.max_triggers_per_run:
				continue

		# 检查冷却
		if _cooldowns.has(event.id):
			continue

		# 检查房间 tags
		if not event.requires_tags.is_empty():
			var has_all_tags := true
			for tag in event.requires_tags:
				if tag not in room_tags:
					has_all_tags = false
					break
			if not has_all_tags:
				continue

		result.append(event)

	return result

func _weighted_random_select(events: Array[RandomEvent]) -> RandomEvent:
	if events.is_empty():
		return null

	var total_weight: float = 0.0
	for event in events:
		total_weight += event.weight

	var random_value: float = randf() * total_weight
	var current_weight: float = 0.0

	for event in events:
		current_weight += event.weight
		if random_value <= current_weight:
			return event

	return events[0]

func _get_event_by_id(event_id: String) -> RandomEvent:
	for event in _events:
		if event.id == event_id:
			return event
	return null

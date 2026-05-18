# ==============================================================================
#   relic_manager.gd
#   功能：遗物管理器（Autoload 单例）。管理玩家获取的遗物和被动效果。
# ==============================================================================
extends Node

# ========================== 常量 ==========================
const MAX_RELICS: int = 8

# ========================== 信号 ==========================
signal relic_added(relic: RelicData)
signal relic_removed(relic: RelicData)
signal relics_changed()

# ========================== 运行时状态 ==========================
var _active_relics: Array[RelicData] = []
var _default_pool: RelicPool = preload("res://resources/data/relics/relic_pool_default.tres")

# ========================== 公共 API ==========================
## 功能：获取遗物（施加被动效果）
## 返回值：true 表示成功获取，false 表示已满且无替换
func acquire_relic(relic: RelicData) -> bool:
	if relic == null:
		return false

	if not relic.is_stackable:
		for existing in _active_relics:
			if existing.id == relic.id:
				UIManager.show_message("已拥有 %s" % relic.display_name)
				return false

	if _active_relics.size() >= MAX_RELICS:
		UIManager.show_message("遗物栏已满（%d/%d）" % [MAX_RELICS, MAX_RELICS])
		return false

	_active_relics.append(relic)
	_apply_passive_effect(relic)
	relic_added.emit(relic)
	relics_changed.emit()
	EventBus.relic_acquired.emit(relic.id)

	UIManager.show_message("获得遗物: %s" % relic.display_name)

	if Global.DEBUG_MODE:
		print("[RelicManager] 获取遗物: ", relic.display_name)
	return true

## 功能：移除遗物
func remove_relic(relic_id: String) -> void:
	for i in _active_relics.size():
		if _active_relics[i].id == relic_id:
			var relic := _active_relics[i]
			_remove_passive_effect(relic)
			_active_relics.remove_at(i)
			relic_removed.emit(relic)
			relics_changed.emit()
			EventBus.relic_lost.emit(relic_id)
			return

## 功能：获取所有活跃遗物
func get_active_relics() -> Array[RelicData]:
	return _active_relics

## 功能：检查是否拥有指定遗物
func has_relic(relic_id: String) -> bool:
	for relic in _active_relics:
		if relic.id == relic_id:
			return true
	return false

## 功能：获取遗物数量
func get_relic_count() -> int:
	return _active_relics.size()

## 功能：清空所有遗物（新运行开始时调用）
func clear_all() -> void:
	for relic in _active_relics:
		_remove_passive_effect(relic)
	_active_relics.clear()
	relics_changed.emit()

## 功能：获取默认遗物池
func get_default_pool() -> RelicPool:
	return _default_pool

# ========================== 内部方法 ==========================
func _apply_passive_effect(relic: RelicData) -> void:
	if relic.passive_effect == null:
		return
	var player := Global.player
	if player and player.status_effect_component:
		player.status_effect_component.apply_effect(relic.passive_effect, self)

func _remove_passive_effect(relic: RelicData) -> void:
	if relic.passive_effect == null:
		return
	var player := Global.player
	if player and player.status_effect_component:
		player.status_effect_component.remove_effect(relic.passive_effect.id)

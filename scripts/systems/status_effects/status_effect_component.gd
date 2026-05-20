# ==============================================================================
#   status_effect_component.gd
#   功能：状态效果管理组件。挂载在实体（Player / Enemy）上，
#        管理该实体身上所有活跃的状态效果，处理施加、移除、Tick、属性汇总。
# ==============================================================================
class_name StatusEffectComponent extends Node

# ========================== 信号 ==========================
signal effect_applied(effect: StatusEffectInstance)
signal effect_removed(effect: StatusEffectInstance)
signal effects_changed()

# ========================== 运行时状态 ==========================
var _active_effects: Array[StatusEffectInstance] = []
var _owner_entity: Node2D

# ========================== 公共 API ==========================
## 功能：初始化组件，绑定宿主实体
## 参数：owner - 被挂载的实体节点（Player 或 Enemy）
func setup(owner_node: Node2D) -> void:
	_owner_entity = owner_node

## 功能：施加一个状态效果
## 参数：effect_type - 效果类型资源，source - 施加来源
func apply_effect(effect_type: StatusEffectType, source: Node2D = null) -> void:
	if effect_type == null or effect_type.id.is_empty():
		return

	# 查找是否已存在同 ID 效果
	var existing := _find_effect(effect_type.id)
	if existing:
		# 根据叠加策略处理
		match effect_type.stack_policy:
			StatusEffectType.StackPolicy.REFRESH:
				existing.refresh_duration()
				return
			StatusEffectType.StackPolicy.STACK:
				if existing.try_add_stack():
					existing.reset_tick_timer()
				return
			StatusEffectType.StackPolicy.REFRESH_OR_STACK:
				existing.refresh_duration()
				if not existing.try_add_stack():
					pass # 已满层，仅刷新
				return

	# 创建新实例
	var instance := StatusEffectInstance.new(effect_type, source)
	_active_effects.append(instance)

	# 执行策略的 on_apply
	if instance.strategy and _owner_entity:
		instance.strategy.on_apply(instance, _owner_entity)

	effect_applied.emit(instance)
	effects_changed.emit()

	# 发送全局信号
	EventBus.status_effect_applied.emit(_owner_entity, instance)

## 功能：移除指定 ID 的效果
## 参数：effect_id - 要移除的效果 ID
func remove_effect(effect_id: String) -> void:
	for i in range(_active_effects.size() - 1, -1, -1):
		if _active_effects[i].get_id() == effect_id:
			var instance := _active_effects[i]
			_remove_instance(instance, i)
			return

## 功能：检查是否拥有指定 ID 的效果
## 返回值：true 表示存在该效果
func has_effect(effect_id: String) -> bool:
	return _find_effect(effect_id) != null

## 功能：获取汇总的速度倍率（所有效果的乘算叠加）
## 返回值：最终速度倍率，如 0.5 表示减速 50%
func get_speed_multiplier() -> float:
	var mult := 1.0
	for instance in _active_effects:
		if instance.strategy:
			mult *= instance.strategy.get_speed_multiplier(instance)
	return mult

## 功能：获取汇总的伤害倍率（所有效果的乘算叠加）
## 返回值：最终伤害倍率
func get_damage_multiplier() -> float:
	var mult := 1.0
	for instance in _active_effects:
		if instance.strategy:
			mult *= instance.strategy.get_damage_multiplier(instance)
	return mult

## 功能：检查实体是否处于眩晕状态
## 返回值：true 表示被眩晕
func is_stunned() -> bool:
	for instance in _active_effects:
		if instance.strategy and instance.strategy.is_stun(instance):
			return true
	return false

## 功能：净化指定数量的减益效果
## 参数：count - 要移除的数量，-1 表示移除全部
## 返回值：实际移除的数量
func purge_debuffs(count: int = -1) -> int:
	var removed := 0
	for i in range(_active_effects.size() - 1, -1, -1):
		if count >= 0 and removed >= count:
			break
		var instance := _active_effects[i]
		if instance.effect_type.is_debuff:
			_remove_instance(instance, i)
			removed += 1
	return removed

## 功能：获取所有活跃效果（只读）
func get_active_effects() -> Array[StatusEffectInstance]:
	return _active_effects

## 功能：清除所有效果
func clear_all() -> void:
	for i in range(_active_effects.size() - 1, -1, -1):
		var instance := _active_effects[i]
		if instance.strategy and _owner_entity:
			instance.strategy.on_remove(instance, _owner_entity)
	_active_effects.clear()
	effects_changed.emit()

# ========================== 内部方法 ==========================
func _ready() -> void:
	# 每帧更新效果计时器
	set_process(true)

func _process(delta: float) -> void:
	if _active_effects.is_empty():
		return

	for i in range(_active_effects.size() - 1, -1, -1):
		var instance := _active_effects[i]

		# 更新剩余时间（永久效果 duration 为 0，跳过）
		if instance.effect_type.duration > 0.0:
			instance.remaining_duration -= delta

		# 检查是否过期
		if instance.is_expired():
			_remove_instance(instance, i)
			continue

		# 更新 tick 计时器
		instance.tick_timer -= delta
		if instance.should_tick() and instance.strategy and _owner_entity:
			instance.strategy.on_tick(instance, _owner_entity, delta)
			instance.reset_tick_timer()
			EventBus.status_effect_ticked.emit(_owner_entity, instance)

func _find_effect(effect_id: String) -> StatusEffectInstance:
	for instance in _active_effects:
		if instance.get_id() == effect_id:
			return instance
	return null

func _remove_instance(instance: StatusEffectInstance, index: int) -> void:
	if instance.strategy and _owner_entity:
		instance.strategy.on_remove(instance, _owner_entity)
	_active_effects.remove_at(index)
	effect_removed.emit(instance)
	effects_changed.emit()
	EventBus.status_effect_removed.emit(_owner_entity, instance)

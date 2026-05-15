# ==============================================================================
#   player_skill_manager.gd
#   功能：技能管理器，管理 SkillRunner 池和技能槽数据，处理冷却信号转发。
#        从 player.gd 拆出的独立组件。
# ==============================================================================
extends Node
class_name PlayerSkillManager

# ========================== 变量定义模块 ==========================
## 技能 ID -> SkillRunner 的映射表（运行时缓存，外部分发技能通过 get_runner() 访问）
var _skill_runners: Dictionary = {}
## 技能槽位数据数组（索引 0~3 对应 skill_1~skill_4）
var _skill_slot_data: Array[SkillEffect] = [
	preload("uid://b765b6el6vbye")
	,VORTEX_01
	,SLASH_FIRE_01,THORNFIRE_01
] 
const VORTEX_01 = preload("uid://bpesntbwo7qn3")
const SLASH_FIRE_01 = preload("uid://ci48eujykiu22")
const THORNFIRE_01 = preload("uid://0sxmye1m7cu2")

## 输入动作名到技能槽位索引的映射
const SKILL_SLOT_MAP: Dictionary = {
	"skill_1": 0,
	"skill_2": 1,
	"skill_3": 2,
	"skill_4": 3,
}

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化所有技能运行器
func _ready() -> void:
	_init_runners()

# ========================== 公共 API 模块 ==========================
## 功能：根据技能 ID 获取技能运行器
## 参数：skill_id (String) - 技能的唯一标识符
## 返回值：SkillRunner - 对应的技能运行器，未找到时返回 null
func get_runner(skill_id: String) -> SkillRunner:
	return _skill_runners.get(skill_id)

## 功能：根据输入动作名获取对应的技能数据
## 参数：action (String) - 输入动作名称（如 "skill_1"）
## 返回值：SkillEffect - 对应的技能数据资源，未找到时返回 null
func get_data_by_action(action: String) -> SkillEffect:
	var idx :int = SKILL_SLOT_MAP.get(action, -1)
	return _skill_slot_data[idx] if idx >= 0 and idx < _skill_slot_data.size() else null

## 功能：装备技能到指定槽位（自动寻找空槽位或覆盖第一个槽位）
## 参数：skill_id (String) - 技能唯一标识符
## 返回值：bool - true 表示装备成功，false 表示技能已在槽中或技能不存在
func equip_skill(skill_id: String) -> bool:
	return equip_skill_to_slot(skill_id, -1)

## 功能：装备技能到指定槽位
## 参数：skill_id (String) - 技能唯一标识符；slot_index (int) - 目标槽位索引（0~3），-1 时自动寻找空槽
## 返回值：bool - true 表示装备成功
func equip_skill_to_slot(skill_id: String, slot_index: int = -1) -> bool:
	var data = SkillLibrary.get_skill_by_id(skill_id)
	if not data:
		return false

	for existing in _skill_slot_data:
		if existing and existing.id == skill_id:
			return false

	if slot_index >= 0 and slot_index < _skill_slot_data.size():
		_skill_slot_data[slot_index] = data
		_recreate_runner(slot_index)
		EventBus.skill_slot_changed.emit(slot_index)
		return true

	# 自动寻找空槽位
	for i in range(_skill_slot_data.size()):
		if not _skill_slot_data[i]:
			_skill_slot_data[i] = data
			_recreate_runner(i)
			EventBus.skill_slot_changed.emit(i)
			return true

	# 所有槽位已满，覆盖第一个
	var old_id = _skill_slot_data[0].id if _skill_slot_data[0] else ""
	_skill_slot_data[0] = data
	_recreate_runner(0, old_id)
	EventBus.skill_slot_changed.emit(0)
	return true

## 功能：获取所有已装备的技能 ID 列表
## 返回值：Array[String] - 已装备技能的 ID 列表
func get_equipped_ids() -> Array:
	var ids: Array = []
	for data in _skill_slot_data:
		if data:
			ids.append(data.id)
	return ids

# ========================== 内部方法模块 ==========================
## 功能：初始化所有技能槽位的 SkillRunner
func _init_runners() -> void:
	var player := get_parent() as Player
	for slot_index in _skill_slot_data.size():
		var slot_data := _skill_slot_data[slot_index]
		var runner := SkillRunner.new(slot_data, player)
		add_child(runner)
		_skill_runners[slot_data.id] = runner
		runner.cooldown_updated.connect(_on_runner_cooldown_updated.bind(slot_index))
		runner.cooldown_finished.connect(_on_runner_cooldown_finished.bind(slot_index))

## 功能：重新创建指定槽位的 SkillRunner，可选清理旧 runner
## 参数：slot_index (int) - 技能槽位索引；old_skill_id (String) - 旧技能 ID（用于清理），null 表示无旧技能
func _recreate_runner(slot_index: int, old_skill_id: String = "") -> void:
	if old_skill_id:
		var old_runner = _skill_runners.get(old_skill_id)
		if old_runner and is_instance_valid(old_runner):
			old_runner.queue_free()
		_skill_runners.erase(old_skill_id)

	var player := get_parent() as Player
	var runner := SkillRunner.new(_skill_slot_data[slot_index], player)
	add_child(runner)
	_skill_runners[_skill_slot_data[slot_index].id] = runner
	runner.cooldown_updated.connect(_on_runner_cooldown_updated.bind(slot_index))
	runner.cooldown_finished.connect(_on_runner_cooldown_finished.bind(slot_index))

# ========================== 信号回调模块 ==========================
## 功能：技能冷却更新时转发到全局事件总线
func _on_runner_cooldown_updated(remaining: float, total: float, slot_index: int) -> void:
	EventBus.skill_cooldown_updated.emit(slot_index, remaining, total)

## 功能：技能冷却结束时转发到全局事件总线
func _on_runner_cooldown_finished(slot_index: int) -> void:
	EventBus.skill_cooldown_finished.emit(slot_index)

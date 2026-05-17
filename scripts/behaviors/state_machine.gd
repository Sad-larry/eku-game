# ==============================================================================
#   state_machine.gd
#   功能：通用有限状态机，管理状态的注册、切换、懒加载、守卫机制和事件转发。
#        支持运行时动态添加状态、转换守卫、以及每帧/物理帧/输入的事件分发。
# ==============================================================================
extends Node
class_name StateMachine

# ========================== 变量定义模块 ==========================
## 状态机所属实体名称（用于调试日志）
var entity_name: String = ""
## 所有已注册状态的字典：{state_name (String): FSMState}
var _states: Dictionary = {}
## 懒加载状态工厂字典：{state_name (String): Callable}，用于延迟创建状态实例
var _state_factories: Dictionary = {}
## 状态转换守卫字典：{"from->to": Callable}，守卫返回 false 时会阻止转换
var _transition_guards: Dictionary = {}
## 当前激活的状态实例
var _current_state: FSMState = null
## 当前状态名称
var current_state_name: String = ""

# ========================== 导出变量模块 ==========================
## 调试模式开关（开启后输出状态切换日志）
@export var DEBUG_MODE: bool = false

# ========================== 状态注册模块 ==========================
## 功能：注册一个状态实例到状态机
## 参数：state_name (String) - 状态名称；state (FSMState) - 状态实例
## 说明：会自动将状态节点添加到状态机节点树下，并注入状态机引用
func add_state(state_name: String, state: FSMState) -> void:
	if _states.has(state_name):
		push_warning("StateMachine: 状态 %s 已存在，将被覆盖" % state_name)
	state.state_machine = self
	# 将状态节点加入场景树（确保其 _ready 等生命周期正常触发）
	add_child(state)
	_states[state_name] = state

## 功能：获取指定名称的状态实例
## 参数：state_name (String) - 状态名称
## 返回值：FSMState - 状态实例，若不存在返回 null
func get_state(state_name: String) -> FSMState:
	return _states.get(state_name)

## 功能：注册懒加载状态工厂（延迟创建状态，适用于循环依赖或减少初始开销）
## 参数：state_name (String) - 状态名称；factory (Callable) - 返回 FSMState 实例的工厂函数
func register_state(state_name: String, factory: Callable) -> void:
	_state_factories[state_name] = factory

# ========================== 状态切换模块 ==========================
## 功能：切换当前状态到指定状态
## 参数：state_name (String) - 目标状态名称
## 说明：会先执行守卫检查，若守卫返回 false 则阻止切换；
##       若目标状态尚未实例化且存在懒加载工厂，则自动创建实例
func change_to(state_name: String) -> void:
	if DEBUG_MODE:
		var tag: String = entity_name if entity_name else "Unknown"
		print("[FSM][%s] %s -> %s" % [tag, current_state_name, state_name])

	var from = current_state_name
	var key = "%s->%s" % [from, state_name]

	# 守卫检查：若存在对应转换守卫且守卫返回 false，则阻止转换
	if _transition_guards.has(key):
		if not _transition_guards[key].call():
			return  # 守卫阻止了转换

	# 检查目标状态是否已注册
	if not _states.has(state_name):
		# 尝试懒加载创建
		if not _state_factories.has(state_name):
			push_error("StateMachine: 找不到状态 %s" % state_name)
			return
		# 调用工厂函数创建状态实例
		var new_state = _state_factories[state_name].call() as FSMState
		new_state.state_machine = self
		_states[state_name] = new_state

	# 退出当前状态（若有）
	if _current_state:
		_current_state.exit()

	# 进入新状态
	_current_state = _states[state_name]
	current_state_name = state_name
	_current_state.enter()

## 功能：添加状态转换守卫（在 from -> to 转换前执行校验）
## 参数：from (String) - 源状态名称；to (String) - 目标状态名称；guard (Callable) - 守卫函数，返回 bool
func add_transition_guard(from: String, to: String, guard: Callable) -> void:
	var key = "%s->%s" % [from, to]
	_transition_guards[key] = guard

# ========================== 状态查询模块 ==========================
## 功能：判断当前状态是否是指定名称
## 参数：state_name (String) - 状态名称
## 返回值：bool - true 表示是当前状态
func is_current_state(state_name: String) -> bool:
	return current_state_name == state_name

## 功能：获取当前状态实例
## 返回值：FSMState - 当前状态实例
## 说明：不推荐直接操作状态实例，优先使用状态机接口
func get_current_state() -> FSMState:
	return _current_state

## 功能：当前状态是否允许移动
## 返回值：bool - true 表示允许移动，false 表示禁止移动
func is_movement_allowed() -> bool:
	return _current_state and _current_state.is_movement_allowed()

# ========================== 事件分发模块 ==========================
## 功能：向当前状态发送自定义事件（如攻击输入、受击等）
## 参数：event_name (String) - 事件名称
func send_event(event_name: String) -> void:
	if _current_state and _current_state.has_method("on_event"):
		_current_state.on_event(event_name)

# ========================== 引擎回调转发模块 ==========================
## 功能：每帧更新（转发给当前状态）
## 参数：delta (float) - 帧间隔时间（秒）
func _process(delta: float) -> void:
	# 暂停状态下阻止状态机继续推进
	if get_tree() and get_tree().paused:
		return
	if _current_state:
		_current_state.update(delta)

## 功能：物理帧更新（转发给当前状态）
## 参数：delta (float) - 物理帧间隔时间（秒）
func _physics_process(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if _current_state:
		_current_state.physics_update(delta)

## 功能：输入事件处理（转发给当前状态）
## 参数：event (InputEvent) - 输入事件对象
func _input(event: InputEvent) -> void:
	if get_tree() and get_tree().paused:
		return
	if _current_state:
		_current_state.handle_input(event)

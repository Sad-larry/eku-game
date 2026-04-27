# scripts/behaviors/state_machine.gd
extends Node
class_name StateMachine

const DEBUG_MODE := true

## 所有注册的状态
var _states: Dictionary = {}
## 懒加载支持
var _state_factories: Dictionary = {}
## 守卫机制
var _transition_guards: Dictionary = {}
## 当前状态实例
var _current_state: FSMState = null
## 当前状态名称
var current_state_name: String = ""

func add_state(state_name: String, state: FSMState) -> void:
	# 注册状态 + 注入 state_machine 引用
	if _states.has(state_name):
		push_warning("StateMachine: 状态 %s 已存在，将被覆盖" % state_name)
	state.state_machine = self
	# 将状态节点加入场景树
	add_child(state)
	_states[state_name] = state

func get_state(state_name: String) -> FSMState:
	return _states.get(state_name)

func change_to(state_name: String) -> void:
	if DEBUG_MODE:
		print("[FSM] %s → %s" % [current_state_name, state_name])
	var from = current_state_name
	var key = "%s→%s" % [from, state_name]
	if _transition_guards.has(key):
		if not _transition_guards[key].call():
			return  # 守卫阻止了转换
	if not _states.has(state_name):
		if not _state_factories.has(state_name):
			push_error("StateMachine: 找不到状态 %s" % state_name)
			return
		# 懒创建
		var new_state = _state_factories[state_name].call() as FSMState
		new_state.state_machine = self
		_states[state_name] = new_state
	if _current_state:
		_current_state.exit()
	_current_state = _states[state_name]
	current_state_name = state_name
	_current_state.enter()

func register_state(state_name: String, factory: Callable) -> void:
	_state_factories[state_name] = factory

func add_transition_guard(from: String, to: String, guard: Callable) -> void:
	var key = "%s→%s" % [from, to]
	_transition_guards[key] = guard

## 当前状态是否是指定名称
func is_current_state(state_name: String) -> bool:
	return current_state_name == state_name

## 获取当前状态实例（用于外部调用特定方法，不推荐直接操作）
func get_current_state() -> FSMState:
	return _current_state

## 发送自定义事件（由具体状态内部处理，例如攻击输入）
func send_event(event_name: String) -> void:
	if _current_state and _current_state.has_method("on_event"):
		_current_state.on_event(event_name)

## 每帧处理
func _process(delta: float) -> void:
	if _current_state:
		_current_state.update(delta)

func _physics_process(delta: float) -> void:
	if _current_state:
		_current_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if _current_state:
		_current_state.handle_input(event)

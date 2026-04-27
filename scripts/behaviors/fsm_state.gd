extends Node
class_name FSMState

## 状态机引用
var state_machine: StateMachine
var _is_active: bool = false

## 进入状态时调用
func enter() -> void:
	_is_active = true

## 退出状态时调用
func exit() -> void:
	_is_active = false

## 每帧更新（_process）
func update(_delta: float) -> void:
	pass

## 物理更新（_physics_process）
func physics_update(_delta: float) -> void:
	pass

## 处理输入事件（可选）
func handle_input(_event: InputEvent) -> void:
	pass

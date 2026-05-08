# ==============================================================================
#   enemy_behavior.gd
#   功能：敌人行为组件基类，以组合方式为敌人添加可插拔的行为模块。
#        通过 Enemy.behaviors 数组挂载，在 Enemy._process() 中每帧驱动。
#   核心优势：行为与状态机分离，可在编辑器自由组合，无需修改代码。
# ==============================================================================
class_name EnemyBehavior
extends Node

# ========================== 变量定义模块 ==========================
## 宿主敌人引用（通过 setup() 注入）
var enemy: Enemy

## 行为启用状态（设为 false 可临时禁用此行为）
var enabled: bool = true

# ========================== 公共 API 模块 ==========================
## 功能：初始化行为，注入敌人引用
func setup(enemy_ref: Enemy) -> void:
	enemy = enemy_ref
	_on_setup()

## 功能：每帧更新（由 Enemy._process() 调用）
func update(delta: float) -> void:
	if not enabled:
		return
	_on_update(delta)

## 功能：敌人死亡时清理（由 Enemy._on_died() 调用）
func cleanup() -> void:
	_on_cleanup()

# ========================== 可重写钩子模块 ==========================
## 功能：初始化时的额外逻辑（子类重写）
func _on_setup() -> void:
	pass

## 功能：每帧更新逻辑（子类重写）
func _on_update(_delta: float) -> void:
	pass

## 功能：清理逻辑（子类重写）
func _on_cleanup() -> void:
	pass

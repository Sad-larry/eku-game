# ==============================================================================
#   damage_popup_spawner.gd
#   功能：伤害数字生成器，采用单例 + 对象池模式管理伤害数字的实例化与回收，
#        提供静态方法供全局调用。挂载于 GameWorld 场景下作为子节点使用。
# ==============================================================================
extends Node
class_name DamagePopupSpawner

# ========================== 常量定义模块 ==========================
const _DAMAGE_NUMBER_SCENE: PackedScene = preload("res://prefabs/fx/damage_number/damage_number.tscn")

# ========================== 静态变量模块 ==========================
static var _instance: DamagePopupSpawner
## 对象池：回收的 DamageNumber 节点
static var _pool: Array[DamageNumber] = []
## z_index 计数器，确保新数字显示在旧数字之上
static var _z_counter: int = 0

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_instance = self

# ========================== 静态公共 API 模块 ==========================
## 功能：在指定位置生成伤害数字
static func show_at(position: Vector2, value: float, type: DamageNumber.DamageType = DamageNumber.DamageType.NORMAL) -> void:
	if _instance == null:
		return
	var popup := _get_from_pool()
	_place(popup, position)
	popup.setup(value, type)

## 功能：在指定位置生成自定义文本飘字（如 "+1 尘元"）
static func show_text_at(position: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if _instance == null:
		return
	var popup := _get_from_pool()
	_place(popup, position)
	popup.setup_text(text, color)

# ========================== 内部方法 ==========================
## 从对象池获取或创建新实例
static func _get_from_pool() -> DamageNumber:
	var popup: DamageNumber
	if _pool.size() > 0:
		popup = _pool.pop_back()
		popup.reset()
	else:
		popup = _instance._DAMAGE_NUMBER_SCENE.instantiate() as DamageNumber
		popup._recycle_callback = _recycle
	return popup

## 放置到场景树并设置层级
static func _place(popup: DamageNumber, position: Vector2) -> void:
	popup.z_index = _z_counter
	_z_counter += 1
	_instance.add_child(popup)
	popup.global_position = position

## 回收至对象池
static func _recycle(popup: DamageNumber) -> void:
	popup.reset()
	if popup.get_parent():
		popup.get_parent().remove_child(popup)
	_pool.push_back(popup)

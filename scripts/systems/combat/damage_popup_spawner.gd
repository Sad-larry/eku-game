# ==============================================================================
#   damage_popup_spawner.gd
#   功能：伤害数字生成器，采用单例模式管理伤害数字控件的实例化与位置设置，
#        提供静态方法供全局调用，自动将生成的数字挂载为子节点。
# ==============================================================================
extends Node
class_name DamagePopupSpawner

# ========================== 导出变量模块 ==========================
## 伤害数字场景资源（需拖入 DamageNumber.tscn 文件）
## 说明：该场景必须包含 DamageNumber 脚本及其所需的 ValueLabel 和 AnimationPlayer 子节点
@export var damage_number_scene: PackedScene

# ========================== 静态变量模块 ==========================
## 静态单例实例，用于在静态方法中访问实例成员
static var _instance: DamagePopupSpawner

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时注册自身为静态单例
func _ready() -> void:
	_instance = self

# ========================== 静态公共 API 模块 ==========================
## 功能：在指定世界坐标位置生成一个伤害数字
## 参数：
##   position (Vector2) - 生成位置的全局坐标（通常为受击者的世界坐标）
##   value (float) - 要显示的伤害/治疗数值
##   is_crit (bool) - 是否为暴击伤害（默认 false，若为 true 则显示金色暴击样式）
## 说明：若单例未初始化（_instance == null）则静默失败，不生成数字
static func show_at(position: Vector2, value: float, is_crit: bool = false) -> void:
	if _instance == null:
		return
	var popup: DamageNumber = _instance.damage_number_scene.instantiate() as DamageNumber
	_instance.add_child(popup)
	popup.global_position = position
	popup.setup(value, is_crit)

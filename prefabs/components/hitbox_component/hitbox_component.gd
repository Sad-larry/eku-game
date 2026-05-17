# ==============================================================================
#   hitbox_component.gd
#   功能：攻击判定框组件，挂载在攻击者身上，用于检测与受击框（HurtboxComponent）的重叠，
#        触发命中信号，并根据阵营系统判断敌对关系。
# ==============================================================================
extends Area2D
class_name HitboxComponent

# ========================== 信号声明模块 ==========================
## 触发时机：Hitbox 检测到有效的 Hurtbox 且双方敌对时触发
## 参数：hurtbox (HurtboxComponent) - 命中的受击框组件（用于后续伤害计算）
signal hit_hurtbox(hurtbox: HurtboxComponent)

# ========================== 变量定义模块 ==========================
## 本次攻击的伤害值
var damage := 1
## 是否为暴击攻击
var critical := false
## 攻击来源节点（攻击者自身，如玩家或敌人）
var source: Node2D
## 阵营组件引用（缓存以提高性能）
var _faction_component: FactionComponent

# ========================== 公共 API 模块 ==========================
## 功能：获取当前攻击框所属阵营
## 返回值：FactionComponent.Faction - 阵营枚举值（未找到时返回 NEUTRAL）
func get_faction() -> FactionComponent.Faction:
	if _faction_component == null:
		return FactionComponent.Faction.NEUTRAL
	return _faction_component.faction

## 功能：启用 Hitbox 的碰撞检测（设为监控状态）
func enable() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

## 功能：禁用 Hitbox 的碰撞检测（停止监控）
func disable() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

## 功能：设置 Hitbox 的攻击参数（通常在攻击开始时调用）
## 参数：damage_args (int) - 伤害值；critical_args (bool) - 是否暴击；source_args (Node2D) - 攻击来源节点
func setup(damage_args: int, critical_args: bool, source_args: Node2D) -> void:
	damage = damage_args
	critical = critical_args
	source = source_args

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时向上查找并缓存阵营组件
func _ready() -> void:
	_faction_component = FactionComponent.find_from(self)

# ========================== 信号回调模块 ==========================
## 功能：检测到其他 Area2D 区域进入时触发
## 参数：area (Area2D) - 进入的碰撞区域
## 说明：判断是否为 HurtboxComponent 且双方敌对，若满足则发射 hit_hurtbox 信号
func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null:
		return
	if not _is_hostile_to(hurtbox):
		return
	hit_hurtbox.emit(hurtbox)
	# TODO: 通过 EventBus 通知伤害计算（待后续整合）
	# EventBus.skill_damage_requested.emit({hurtbox.get_parent(), damage, critical, source})

# ========================== 辅助方法模块 ==========================
## 功能：判断当前 Hitbox 是否与目标 Hurtbox 敌对
## 参数：hurtbox (HurtboxComponent) - 目标受击框
## 返回值：bool - true 表示敌对，应造成伤害；false 表示为友方/中立，不造成伤害
func _is_hostile_to(hurtbox: HurtboxComponent) -> bool:
	var target_faction := hurtbox.get_faction()
	return FactionComponent.is_hostile(get_faction(), target_faction)

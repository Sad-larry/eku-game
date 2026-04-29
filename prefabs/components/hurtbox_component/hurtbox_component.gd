# ==============================================================================
#   HurtboxComponent.gd
#   功能：受击判定框组件，挂载在可受击实体上，用于检测攻击判定框（HitboxComponent）的进入，
#        触发受击信号，并根据阵营系统判断敌对关系。
# ==============================================================================
extends Area2D
class_name HurtboxComponent

# ========================== 信号声明模块 ==========================
## 触发时机：Hurtbox 检测到有效的 Hitbox 且双方敌对时触发
## 参数：hitbox (HitboxComponent) - 命中的攻击判定框组件（包含伤害值、暴击状态等）
signal damaged(hitbox: HitboxComponent)

# ========================== 变量定义模块 ==========================
## 阵营组件引用（缓存以提高性能）
var _faction_component: FactionComponent

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时向上查找并缓存阵营组件
func _ready() -> void:
	_faction_component = FactionComponent.find_from(self)

# ========================== 公共 API 模块 ==========================
## 功能：获取当前受击框所属阵营
## 返回值：FactionComponent.Faction - 阵营枚举值（未找到时返回 NEUTRAL）
func get_faction() -> FactionComponent.Faction:
	if _faction_component == null:
		return FactionComponent.Faction.NEUTRAL
	return _faction_component.faction

# ========================== 信号回调模块 ==========================
## 功能：检测到其他 Area2D 区域进入时触发
## 参数：area (Area2D) - 进入的碰撞区域
## 说明：判断是否为 HitboxComponent 且双方敌对，若满足则发射 damaged 信号
func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as HitboxComponent
	if hitbox == null:
		return
	if not _is_hostile_to(hitbox):
		return
	damaged.emit(hitbox)

# ========================== 辅助方法模块 ==========================
## 功能：判断当前 Hurtbox 是否与目标 Hitbox 敌对
## 参数：hitbox (HitboxComponent) - 目标攻击判定框
## 返回值：bool - true 表示敌对，应受到伤害；false 表示为友方/中立，不受伤害
func _is_hostile_to(hitbox: HitboxComponent) -> bool:
	var hitbox_faction: FactionComponent.Faction = hitbox.get_faction()
	return FactionComponent.is_hostile(get_faction(), hitbox_faction)

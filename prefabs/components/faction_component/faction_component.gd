# ==============================================================================
#   FactionComponent.gd
#   功能：阵营组件，用于标识实体所属阵营（玩家、敌人、中立），并提供阵营敌对关系判断、
#        向上查找实体阵营组件的静态方法。
# ==============================================================================
extends Node
class_name FactionComponent

# ========================== 枚举定义模块 ==========================
## 阵营类型枚举
enum Faction {
	PLAYER,   ## 玩家阵营
	ENEMY,    ## 敌人阵营
	NEUTRAL,  ## 中立阵营（不主动攻击，不受攻击影响）
}

# ========================== 导出变量模块 ==========================
## 当前实体所属阵营（默认为中立）
@export var faction: Faction = Faction.NEUTRAL

# ========================== 静态方法模块 ==========================
## 功能：判断两个阵营是否为敌对关系
## 参数：a (Faction) - 阵营 A；b (Faction) - 阵营 B
## 返回值：bool - true 表示敌对，false 表示非敌对（相同阵营或中立相关）
## 说明：当前敌对规则仅为 玩家 ↔ 敌人 互为敌对，中立阵营不参与敌对
static func is_hostile(a: Faction, b: Faction) -> bool:
	return (a == Faction.PLAYER and b == Faction.ENEMY) \
		or (a == Faction.ENEMY and b == Faction.PLAYER)

## 功能：从任意节点向上遍历查找其所在实体的 FactionComponent
## 参数：node (Node) - 起始节点（通常是组件或子节点）
## 返回值：FactionComponent - 找到的阵营组件实例，若未找到则返回 null
## 说明：查找顺序为从当前节点开始，逐级向上检查父节点，直到找到名为 "FactionComponent" 的子节点或到达根节点
static func find_from(node: Node) -> FactionComponent:
	var current = node
	while current:
		var fc = current.get_node_or_null("FactionComponent") as FactionComponent
		if fc:
			return fc
		current = current.get_parent()
	return null

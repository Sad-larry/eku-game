extends Node
class_name FactionComponent

# 阵营系统
enum Faction {
	PLAYER,
	ENEMY,
	NEUTRAL,
}

## 当前实体所属阵营
@export var faction: Faction = Faction.NEUTRAL

## 返回两个阵营是否为敌对关系
static func is_hostile(a: Faction, b: Faction) -> bool:
	return (a == Faction.PLAYER and b == Faction.ENEMY) \
		or (a == Faction.ENEMY and b == Faction.PLAYER)

## 从任意节点向上查找其所在实体的 FactionComponent
static func find_from(node: Node) -> FactionComponent:
	var current = node
	while current:
		var fc = current.get_node_or_null("FactionComponent") as FactionComponent
		if fc:
			return fc
		current = current.get_parent()
	return null

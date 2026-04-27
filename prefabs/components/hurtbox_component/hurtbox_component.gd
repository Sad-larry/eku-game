extends Area2D
class_name HurtboxComponent

signal damaged(hitbox: HitboxComponent)

var _faction_component: FactionComponent

func _ready() -> void:
	_faction_component = FactionComponent.find_from(self)

func get_faction() -> FactionComponent.Faction:
	if _faction_component == null:
		return FactionComponent.Faction.NEUTRAL
	return _faction_component.faction

func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as HitboxComponent
	if hitbox == null:
		return
	if not _is_hostile_to(hitbox):
		return
	damaged.emit(hitbox)

# 阵营敌对判定
func _is_hostile_to(hitbox: HitboxComponent) -> bool:
	var hitbox_faction: FactionComponent.Faction = hitbox.get_faction()
	return FactionComponent.is_hostile(get_faction(), hitbox_faction)

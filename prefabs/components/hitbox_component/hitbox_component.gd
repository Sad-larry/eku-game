extends Area2D
class_name HitboxComponent

signal hit_hurtbox(hurtbox: HurtboxComponent)

var damage := 1
var critical := false
var source: Node2D

var _faction_component: FactionComponent

func get_faction() -> FactionComponent.Faction:
	if _faction_component == null:
		return FactionComponent.Faction.NEUTRAL
	return _faction_component.faction

func _ready() -> void:
	_faction_component = FactionComponent.find_from(self)

func enable() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func disable() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func setup(damage_args: int, critical_args: bool, source_args: Node2D) -> void:
	damage = damage_args
	critical = critical_args
	source = source_args

func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null:
		return
	if not _is_hostile_to(hurtbox):
		return
	hit_hurtbox.emit(hurtbox)

func _is_hostile_to(hurtbox: HurtboxComponent) -> bool:
	var target_faction := hurtbox.get_faction()
	return FactionComponent.is_hostile(get_faction(), target_faction)

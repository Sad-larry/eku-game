# ==============================================================================
#   terrain_effect_zone.gd
#   功能：地形效果区域。当玩家/敌人在此区域内时，持续施加生态对应的状态效果。
# ==============================================================================
# [重构注释] 2.5D等距地图相关代码已暂时禁用
# class_name TerrainEffectZone extends Node2D
#
# var _biome_config: BiomeConfig
# var _entities_in_zone: Array[Node2D] = []
# var _effect_timer: float = 0.0
#
# ## 功能：初始化地形效果区域
# func setup(biome: BiomeConfig) -> void:
# 	_biome_config = biome
# 	_effect_timer = biome.terrain_effect_interval
#
# ## 功能：每帧检查效果施加
# func _process(delta: float) -> void:
# 	if _biome_config == null or _biome_config.terrain_effects.is_empty():
# 		return
#
# 	_effect_timer -= delta
# 	if _effect_timer <= 0.0:
# 		_effect_timer = _biome_config.terrain_effect_interval
# 		_apply_effects_to_entities()
#
# ## 功能：实体进入区域
# func _on_area_body_entered(body: Node2D) -> void:
# 	if body is Player or body is Enemy:
# 		if body not in _entities_in_zone:
# 			_entities_in_zone.append(body)
#
# ## 功能：实体离开区域
# func _on_area_body_exited(body: Node2D) -> void:
# 	_entities_in_zone.erase(body)
#
# func _apply_effects_to_entities() -> void:
# 	for entity in _entities_in_zone:
# 		if not is_instance_valid(entity):
# 			continue
# 		var se_component: StatusEffectComponent = entity.get("status_effect_component")
# 		if se_component == null:
# 			continue
# 		for effect_type in _biome_config.terrain_effects:
# 			if effect_type is StatusEffectType:
# 				se_component.apply_effect(effect_type, self)

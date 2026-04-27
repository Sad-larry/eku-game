# resources/data/rooms/room_resource.gd
extends Resource
class_name RoomResource

@export var waves: Array[WaveData]        # 波次列表
@export var default_enemy_scene: PackedScene   # 默认敌人场景（无波次时用）

# 如果需要房间奖励，可添加 loot_table 字段

# ==============================================================================
#   relic_data.gd
#   功能：遗物数据资源。定义一个遗物的基本信息和被动效果。
# ==============================================================================
class_name RelicData extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
## 被动效果（通过 StatusEffectComponent 施加，duration=0 表示永久）
@export var passive_effect: StatusEffectType
## 是否可叠加获取
@export var is_stackable: bool = false

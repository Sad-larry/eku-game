# ==============================================================================
#   relic_data.gd
#   功能：遗物数据资源。定义一个遗物的基本信息和被动效果。
# ==============================================================================
class_name RelicData extends Resource

## 遗物稀有度枚举
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# ========================== 基本信息模块 ==========================
## 遗物唯一标识符
@export var id: String = ""
## 遗物显示名称（UI 展示用）
@export var display_name: String = ""
## 遗物效果描述文本
@export var description: String = ""
## 遗物图标
@export var icon: Texture2D
## 遗物稀有度（影响掉落概率和效果强度）
@export var rarity: Rarity = Rarity.COMMON

# ========================== 效果模块 ==========================
## 被动效果（通过 StatusEffectComponent 施加，duration=0 表示永久）
@export var passive_effect: StatusEffectType
## 是否可叠加获取（true=重复获取效果叠加，false=重复获取无效）
@export var is_stackable: bool = false

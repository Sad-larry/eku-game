# ==============================================================================
#   random_event.gd
#   功能：随机事件资源类，定义冒险中可能触发的随机事件。
# ==============================================================================
extends Resource
class_name RandomEvent

## 事件唯一标识符
@export var id: String = ""
## 事件显示名称
@export var display_name: String = ""
## 事件描述
@export var description: String = ""
# ========================== 触发条件 ==========================
## 最小 ring 要求
@export var min_ring: int = 1
## 最大 ring 要求
@export var max_ring: int = 99
## 触发权重（相对于其他事件的权重）
@export var weight: float = 1.0
## 房间需要的 tags（为空则不限制）
@export var requires_tags: Array[String] = []
# ========================== 事件效果 ==========================
## 事件类型（对应 RoomContentGenerator 的 event_type）
@export var event_type: String = ""
## 额外奖励配置
@export var bonus_rewards: Dictionary = {}
# ========================== 触发限制 ==========================
## 每次运行最多触发次数（0=无限制）
@export var max_triggers_per_run: int = 1
## 触发后冷却的房间数
@export var cooldown_rooms: int = 0
# ========================== 视觉 ==========================
## 事件图标
@export var icon: Texture2D
## 事件提示文本
@export var tooltip: String = ""

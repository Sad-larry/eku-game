# ==============================================================================
#   guaranteed_event_info.gd
#   功能：保证事件信息——将某个事件类型固定在指定圈层出现
#         用于配置菱形网格地图中，哪一圈必须固定刷出哪种特定事件
# ==============================================================================

extends Resource
class_name GuaranteedEventInfo

# ========================== 枚举声明 ==========================

## 事件类型枚举
enum Eventtpye {
	## 起点事件（仅第一圈生成）
	START,
	## BOSS 战斗事件
	BOSS,
	## 普通小怪战斗
	BATTLE,
	## 精英怪战斗事件（难度高于普通，低于 BOSS）
	ELITE,
	## 商人/商店事件（可购买道具）
	MERCHANT,
	## 宝箱/宝藏事件
	TREASURE,
	## 休息/回血事件
	REST,
	## 随机事件（多分支选择）
	RANDOM,
	## 陷阱事件
	TRAP,
	## NPC 对话/任务事件
	NPC,
	## 传送/跳转事件
	TELEPORT,
	## 隐藏房间/秘密事件
	HIDDEN,
}

# ========================== 导出变量 ==========================

## 目标圈层索引（0 表示起始圈，第一圈 = 0，第二圈 = 1，以此类推）
@export var ring_index: int

## 固定刷出的事件类型
@export var event_type: Eventtpye

# ========================== 静态方法 ==========================

## 功能：将 Eventtpye 枚举转换为配置表用的字符串标识
## 参数：type (Eventtpye) - 事件类型枚举值
## 返回值：String - 对应的事件字符串标识，如 "start", "boss", "merchant" 等
static func type_to_string(type: Eventtpye) -> String:
	match type:
		Eventtpye.START: return "start"
		Eventtpye.BOSS: return "boss"
		Eventtpye.MERCHANT: return "merchant"
		Eventtpye.TREASURE: return "treasure"
		Eventtpye.REST: return "rest"
		Eventtpye.ELITE: return "elite"
		Eventtpye.BATTLE: return "battle"
		Eventtpye.RANDOM: return "random"
		Eventtpye.TRAP: return "trap"
		Eventtpye.NPC: return "npc"
		Eventtpye.TELEPORT: return "teleport"
		Eventtpye.HIDDEN: return "hidden"
		_: return ""

# ==============================================================================
#   codex_entry.gd
#   功能：图鉴条目资源类，定义图鉴中显示的敌人/技能/遗物/武器信息。
# ==============================================================================
extends Resource
class_name CodexEntry

## 图鉴类型枚举
enum CodexType {
	## 敌人图鉴
	ENEMY,
	## 技能图鉴
	SKILL,
	## 遗物图鉴
	RELIC,
	## 武器图鉴
	WEAPON,
	## BOSS图鉴
	BOSS
}

## 条目唯一标识符
@export var id: String = ""
## 条目显示名称
@export var display_name: String = ""
## 条目描述
@export var description: String = ""
## 条目图标
@export var icon: Texture2D
## 图鉴类型
@export var codex_type: CodexType = CodexType.ENEMY
## 背景故事/图鉴文本
@export var lore_text: String = ""
## 解锁条件描述
@export var unlock_condition: String = ""

# ========================== 敌人图鉴专用 ==========================
## 敌人属性显示（用于图鉴详情）
@export var enemy_stats_display: Dictionary = {}

# ========================== 技能图鉴专用 ==========================
## 技能标签显示
@export var skill_tags_display: Array[String] = []

# ========================== 排序 ==========================
## 排序优先级
@export var sort_order: int = 0

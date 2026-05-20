# ==============================================================================
#   global.gd
#   功能：全局单例，提供全局常量（场景路径/预制体）、调试开关、全局玩家引用。
#   说明：所有脚本均可通过 Global.xxx 访问。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 Global
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 调试模式开关（开启后输出更多调试信息）
const DEBUG_MODE: bool = true

## 主菜单场景路径
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main/main_menu.tscn"
## 游戏大厅场景路径
const GAME_LOBBY_SCENE_PATH: String = "res://scenes/lobby/lobby_world.tscn"
## 游戏场景路径
const GAME_WORLD_SCENE_PATH: String = "res://scenes/game/game_world.tscn"
## 技能卡片场景（技能选择面板中实例化）
const SKILL_CARD_SCENE: PackedScene = preload("res://prefabs/ui/skill_selection_card/skill_selection_card.tscn")
## 安全区标记场景（出生点 / 休息区共用）
const SAFE_ZONE_SCENE: PackedScene = preload("res://prefabs/environment/safe_zone/safe_zone_marker.tscn")


# ========================== 运行时实体引用模块 ==========================
## 全局玩家对象引用
## 说明：由 Player._ready() 自动赋值，Player._exit_tree() 自动清空。
##       外部通过 Global.player 访问，禁止直接对 player 属性赋值（setter 会做保护性检查）
var player: Player:
	set(value):
		# 防止外部随意覆盖已有引用（调试模式下会输出警告）
		if DEBUG_MODE and player != null and value != null:
			print("Global.player: 正在覆盖已有引用，旧玩家可能未被正确清理")
			return
		player = value
	get:
		return player

# ========================== 生命周期模块 ==========================
## 功能：全局单例就绪时初始化随机种子
func _ready() -> void:
	# 初始化随机数生成器种子（确保 randf() 结果在不同运行时有差异）
	randomize()
	print("Global: 全局单例初始化完成")

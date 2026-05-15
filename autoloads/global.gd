# ==============================================================================
#   global.gd
#   功能：全局单例，提供通用枚举、工具函数（概率判定、权重随机）、全局常量
#        （场景路径）、全局玩家引用、音量/显示配置、当前关卡信息等。
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

const SKILL_CARD_SCENE: String = "res://prefabs/ui/skill_selection_card/skill_selection_card.tscn"


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

# ========================== 游戏配置模块（运行时）==========================
## 主音量（范围 0.0 - 1.0），音频管理器会读取此值
var master_volume: float = 1.0
## 音乐音量（范围 0.0 - 1.0），音频管理器会读取此值
var music_volume: float = 0.8
## 音效音量（范围 0.0 - 1.0），音频管理器会读取此值
var sfx_volume: float = 1.0
## 是否全屏模式
var fullscreen: bool = false
## 屏幕分辨率（宽度 x 高度）
var resolution: Vector2i = Vector2i(1280, 720)

# ========================== 当前关卡信息模块 ==========================
## 当前所在的房间/关卡 ID（由 RoomManager 切换房间时更新）
var current_room_id: String = ""
## 当前关卡的类型（RoomConfig.RoomType 枚举值，由 RoomManager 切换房间时更新）
var current_room_type: int = -1

# ========================== 生命周期模块 ==========================
## 功能：全局单例就绪时初始化随机种子
func _ready() -> void:
	# 初始化随机数生成器种子（确保 randf() 结果在不同运行时有差异）
	randomize()
	print("Global: 全局单例初始化完成")

# ========================== 工具函数模块 ==========================
## 功能：概率判定函数
## 参数：probability (float) - 目标概率，范围 0.0 - 1.0
## 返回值：bool - true 表示命中（概率成功），false 表示未命中
## 示例：get_chance_success(0.75) 返回 true 的概率为 75%
func get_chance_success(probability: float) -> bool:
	return randf() < probability

## 功能：在数组中按权重随机选择一个元素
## 参数：items (Array) - 待选择的元素数组；weights (Array[float]) - 对应的权重数组
## 返回值：混合类型 - 随机选中的元素，若参数无效则返回 null
## 说明：weights 数组长度必须与 items 数组长度一致；总权重为各权重之和
## 示例：weighted_random(["铁剑", "木盾", "药水"], [10.0, 5.0, 3.0])
func weighted_random(items: Array, weights: Array[float]):
	# 参数校验
	if items.is_empty() or weights.is_empty():
		return null
	if items.size() != weights.size():
		push_error("Global.weighted_random: items 和 weights 长度不一致")
		return null
	
	# 计算总权重
	var total: float = 0.0
	for w in weights:
		total += w
	
	# 若所有权重为 0（或总和为 0），则退化为均匀随机
	if total <= 0.0:
		return items[randi() % items.size()]
	
	# 按权重随机抽取
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in items.size():
		cumulative += weights[i]
		if roll < cumulative:
			return items[i]
	
	# 兜底返回（理论上不会执行到这里）
	return items[-1]

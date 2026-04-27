# autoloads/global.gd
# 全局单例：全局信号总线、通用枚举、工具函数（如数学运算、类型转换），所有单例均可访问
extends Node

# ========================== 常量定义 ==========================
# 调试开关
const DEBUG_MODE: bool = true

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main/main_menu.tscn"
const GAME_LOBBY_SCENE_PATH: String = "res://scenes/lobby/game_lobby.tscn"
const ROOM_01_SCENE_PATH: String = "res://scenes/game/room_01/room_01.tscn"


# ========================== 生命周期 ==========================
func _ready() -> void:
	# 初始化随机种子
	randomize()
	print("Global: 全局单例初始化完成")
	
# ========================== 工具函数 ==========================
# 概率判定工具：根据归一化概率 (0.0 ~ 1.0) 返回是否成功
# 例如：传入 0.75 表示 75% 几率返回 true
func get_chance_success(probability: float) -> bool:
	return randf() < probability

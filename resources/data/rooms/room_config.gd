# ==============================================================================
#   room_config.gd
#   功能：房间配置资源，定义单个房间/关卡的所有内容（地形布局、敌人波次、
#        生成点覆盖、奖励、视听配置等）。每关对应一个独立的 RoomConfig 实例。
# ==============================================================================
extends Resource
class_name RoomConfig

# ========================== 枚举定义模块 ==========================
## 房间类型枚举
enum RoomType {
	LOBBY,   ## 大厅/主城（无战斗）
	NORMAL,  ## 普通战斗房间
	BOSS,    ## Boss 战斗房间
	SHOP     ## 商店房间（无战斗）
}

# ========================== 导出变量模块 ==========================
# ----- 基本属性 -----
## 房间唯一标识符
@export var room_id: String = ""

## 房间显示名称（用于 UI 展示）
@export var room_display_name: String = ""

## 房间类型（影响战斗逻辑和奖励结算）
@export var room_type: RoomType = RoomType.NORMAL

# ----- 地形引用（核心）-----
## 引用一个 RoomLayout 资源，决定本房间的地形、碰撞、生成点位置
@export var layout: RoomLayout

# ----- 敌人配置 -----
## 波次配置（复用 WaveData 资源），支持多波次战斗
## 若 waves 非空，则优先使用波次系统生成敌人
@export var waves: Array[WaveData]

## 生成点覆盖列表，用于将 layout 中的抽象 marker_id 绑定到具体的敌人场景
@export var spawn_overrides: Array[SpawnOverride]

# ----- 奖励配置 -----
## 通关奖励资源（后续可替换为 LootTable 类型）
@export var reward_table: Resource

# ----- 视听配置 -----
## 房间环境色（用于氛围渲染）
@export var ambient_color: Color = Color(1, 1, 1, 1)

## 房间背景音乐（播放时自动切换）
@export var music_track: AudioStream

# ========================== 内嵌类定义模块 ==========================
## 生成点覆盖配置 — 把 RoomLayout 里的抽象 marker_id 绑定到具体敌人场景
class SpawnOverride:
	extends Resource

	## 对应 RoomLayout.spawn_marker_templates 中的 marker_id
	@export var marker_id: String = ""

	## 该生成点需要生成的敌人场景
	@export var enemy_scene: PackedScene

	## 随机权重（供后续波次随机选择敌人时使用）
	@export var spawn_weight: float = 1.0

# ========================== 辅助方法模块 ==========================
## 功能：查找指定 marker_id 的覆盖配置
## 参数：marker_id (String) - 生成点标识符
## 返回值：SpawnOverride - 找到的覆盖配置，若未找到则返回 null
func find_override(marker_id: String) -> SpawnOverride:
	for o in spawn_overrides:
		if o.marker_id == marker_id:
			return o
	return null

## 功能：判断房间是否包含战斗内容（非大厅/非商店，且有波次或生成点覆盖）
## 返回值：bool - true 表示有战斗内容，false 表示无战斗（如大厅或商店）
func has_combat() -> bool:
	if room_type == RoomType.LOBBY or room_type == RoomType.SHOP:
		return false
	return not waves.is_empty() or not spawn_overrides.is_empty()

extends Node2D
class_name RoomBase

# 房间配置（可通过资源文件扩展）
@export var room_id: String = "empty_room_01"  # 房间唯一标识
@export var is_battle_room: bool = false  # 是否为战斗房间（预留）

# 节点引用
@onready var collision_container = $Collision

# 初始化
func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)

# 游戏状态变化回调
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.IN_GAME:
			collision_container.set_process(true)
		GameManager.GameState.PAUSED:
			collision_container.set_process(false)
		_:
			pass

# 房间激活（进入房间时调用）
func activate_room() -> void:
	visible = true
	collision_container.set_physics_process(true)
	# 可扩展：生成敌人、播放房间激活音效等
	if Global:
		Global.set_current_room(room_id)

# 房间休眠（离开房间时调用）
func deactivate_room() -> void:
	visible = false
	collision_container.set_physics_process(false)
	# 可扩展：清理敌人、停止房间音效等

# 清理资源
func _exit_tree() -> void:
	#Global.unregister_room(self)
	pass

func _on_end_body_entered(_body: Node2D) -> void:
	UIManager.open_game_over()

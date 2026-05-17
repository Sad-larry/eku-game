# ==============================================================================
#   enemy_attack_state.gd
#   功能：敌人攻击状态，进入时播放攻击动画、执行攻击逻辑，等待动画完成后
#        切换至冷却状态。
# ==============================================================================
extends EnemyState
class_name EnemyAttackState

# ========================== 内部变量模块 ==========================
## 标记是否已连接过 anim_finished 信号（防止重复连接）
var _connected: bool = false

# ========================== 状态生命周期模块 ==========================
func enter() -> void:
	# 调用父类 enter 方法（设置 _is_active = true）
	super()
	get_anim().play_state("attack")
	
	# 执行攻击逻辑
	_enemy.attack()
	
	# 连接动画完成信号
	if not _connected:
		get_anim().anim_finished.connect(_on_attack_anim_finished)
		_connected = true

func exit() -> void:
	super()
	# 攻击结束时禁用判定框
	if is_instance_valid(_enemy.hitbox_component):
		_enemy.hitbox_component.disable()

# ========================== 信号回调模块 ==========================
func _on_attack_anim_finished(anim_name: StringName) -> void:
	if anim_name != "attack" or not _is_active:
		return
	state_machine.change_to("cooldown")

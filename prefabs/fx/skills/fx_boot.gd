# ==============================================================================
#   fx_boot.gd
#   功能：特效引导基类（极简框架）。提供生命周期模式枚举、预览模式支持、
#        动画播放器自动查找、以及统一暂停行为。具体移动/跟随/销毁逻辑
#        全部由子类实现，基类不预设任何自动行为。
# ==============================================================================
extends Node2D
class_name FxBoot

# ========================== 枚举模块 ==========================
## 生命周期模式（仅供子类参考，基类不自动处理任何模式）
enum LifetimeMode {
	ONESHOT,      # 一次性特效（子类可自行决定播放后销毁）
	FLYING,       # 飞行特效（子类需实现移动和命中销毁）
	FOLLOW,       # 跟随特效（子类需每帧更新位置）
	STATIC,       # 定点持续特效（子类可计时销毁）
	MANUAL        # 完全手动控制（由外部调用 destroy）
}

## 动画播放器默认播放的动画名字
const ANIM_NAME :String = "slash"

# ========================== 导出变量模块 ==========================
## 生命周期模式（子类可在 _init 或 _ready 中设置）
@export var lifetime_mode: LifetimeMode = LifetimeMode.ONESHOT

# ========================== 内部变量模块 ==========================
## 技能释放者（攻击方）
var caster: Node2D
## 技能目标（受击方）
var target: Node2D
## 目标世界坐标（用于无 target 节点时的位置）
var target_pos: Vector2 = Vector2.ZERO
## 技能数据
var skill_data: SkillEffect

## SkillRunner 引用（由 SkillRunner.execute() 自动注入，子类通过此引用调用 on_hit 等方法）
var runner: SkillRunner

## 预览模式标志（由外部设置）
var is_preview: bool = false:
	set(value):
		is_preview = value
		if is_preview and is_inside_tree():
			_setup_preview()

## 是否正在运行中（子类可用作状态标志）
var is_running: bool = false

# ========================== 节点引用模块 ==========================
## 动画播放器节点（自动查找任意深度的子节点，若不存在则为 null）
var animation_player: AnimationPlayer:
	get:
		if not _animation_player:
			_animation_player = find_child("AnimationPlayer", true, false)
		return _animation_player
var _animation_player: AnimationPlayer = null

# ========================== 生命周期模块 ==========================
#func _enter_tree() -> void:
	# 统一暂停行为：游戏打开菜单时特效也暂停
	#process_mode = PROCESS_MODE_WHEN_PAUSED

func _ready() -> void:
	if is_preview:
		_setup_preview()
		return
	# 启动特效（子类可重写 start 或在其后添加逻辑）
	start()

func _exit_tree() -> void:
	if is_instance_valid(runner):
		runner.on_fx_destroyed()

## 每帧更新（基类根据模式调用对应虚函数，子类按需重写）
func _process(delta: float) -> void:
	if is_preview:
		return
	match lifetime_mode:
		LifetimeMode.FLYING, LifetimeMode.FOLLOW:
			_update_movement(delta)
		LifetimeMode.STATIC:
			_update_static(delta)
		_:
			pass

# ========================== 虚函数（子类按需重写） ==========================
## 启动特效（子类可重写，但建议调用 super.start() 以执行默认定位和播动画）
func start() -> void:
	if is_preview:
		return
	is_running = true
	setup_position()
	play_animation()
	# 注意：基类不自动处理销毁，子类需自行在适当时机调用 destroy()
	# 例如在动画结束信号中调用，或在 _update_movement 中判断条件后调用

## 设置特效位置（子类**必须**重写以实现正确的定位逻辑）
## 说明：基类默认实现只是简单地将特效置于 caster 位置，通常不能满足需求，
##       子类应重写并实现具体定位（例如跟随目标、偏移等）。
func setup_position() -> void:
	if caster:
		global_position = caster.global_position
	elif target:
		global_position = target.global_position
	else:
		global_position = target_pos

## 播放特效动画（子类**建议**重写，以播放指定的动画名）
## 说明：基类默认播放名为 "slash" 的动画或第一个动画，若无动画则静默失败。
func play_animation() -> void:
	if not animation_player:
		return
	var anim_list = animation_player.get_animation_list()
	if anim_list.is_empty():
		return	
	if animation_player.has_animation(ANIM_NAME):
		animation_player.play(ANIM_NAME)

## 每帧移动/跟随逻辑（仅当 lifetime_mode 为 FLYING 或 FOLLOW 时被调用）
## 子类**必须**重写以实现移动或跟随
func _update_movement(_delta: float) -> void:
	pass

## 每帧定点持续逻辑（仅当 lifetime_mode 为 STATIC 时被调用）
## 子类可按需重写，例如实现计时器并在到期时调用 destroy()
func _update_static(_delta: float) -> void:
	pass

## 销毁特效（子类可在适当时机调用）
## 说明：基类直接 queue_free，子类可重写以实现对象池或其他清理逻辑
func destroy() -> void:
	queue_free()

## 重置特效状态（用于对象池复用，子类应重写并调用 super.reset()）
func reset() -> void:
	caster = null
	target = null
	target_pos = Vector2.ZERO
	skill_data = null
	is_preview = false
	is_running = false
	_animation_player = null
	if animation_player:
		animation_player.stop()

# ========================== 预览模式模块 ==========================
## 预览模式设置（自动居中父容器，停止任何自动销毁）
func _setup_preview() -> void:
	# 居中于父容器（如果有 Control 父节点）
	if get_parent() is Control:
		position = (get_parent().size - (get_viewport_rect().size * scale)) / 2
	else:
		global_position = Vector2.ZERO

	# 播放预览动画（优先 "preview"，否则第一个动画）
	if animation_player:
		if animation_player.has_animation("preview"):
			animation_player.play("preview")
		elif animation_player.get_animation_list().size() > 0:
			animation_player.play(animation_player.get_animation_list()[0])

	_setup_preview_custom()

## 子类可重写此方法以自定义预览行为（例如调整缩放、偏移）
func _setup_preview_custom() -> void:
	pass

## 外部调用，手动设置预览时的位置（若默认居中不符合需求）
func set_preview_position(new_pos: Vector2) -> void:
	if is_preview:
		position = new_pos
